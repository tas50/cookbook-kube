require 'cheffish/chef_run'
require 'chef'

require 'command_generator'
require 'kube_apiserver'

require 'minitest/autorun'

class ApiServerTest < Minitest::Test
  include KubernetesCookbook

  def kube_apiserver
    @server ||= KubeApiserver.new 'default'
  end

  def test_has_a_name
    assert_equal 'default', kube_apiserver.name
  end

  def test_default_action_is_create
    assert_equal [:create], kube_apiserver.action
  end

  def test_default_options_is_a_hash
    assert_equal({}, kube_apiserver.options)
  end
end

module Provider
  require_relative 'provider_helper'
  include ChefContext

  def provider(action = :start, &block)
    @provider ||= begin
      resource = chefrun.compile_recipe do
        kube_apiserver 'testing', &block
      end
      provider = resource.provider_for_action(:create)
      provider.extend ProviderInspection
    end
  end
end

class ActionCreateTest < Minitest::Test
  include Provider

  def test_passes_the_source_remote
    provider do
      remote 'https://somewhere/kube-apiserver'
    end

    provider.action_create

    binary = provider.inline_resources.find 'remote_file[kube-apiserver binary]'

    assert_equal 'https:///kube-apiserver', binary.source
  end

  def test_passes_the_source_remote
    provider :create do
      checksum 'the-checksum'
    end

    provider.action_create

    binary = provider.inline_resources.find 'remote_file[kube-apiserver binary]'

    assert_equal 'the-checksum', binary.checksum
  end
end

class ActionStartTest < Minitest::Test
  include Provider

  def test_passes_apiserver_command_to_systemd_unit
    provider do
      options an_option: 'some-value'
    end
    provider.action_start
    unit = provider.inline_resources.find 'template[/etc/systemd/system'\
        '/kube-apiserver.service]'

    command = unit.variables[:kube_apiserver_command]
    assert_equal '/usr/sbin/kube-apiserver --an-option=some-value', command
  end
end
