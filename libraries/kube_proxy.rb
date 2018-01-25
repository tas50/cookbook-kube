module KubernetesCookbook
  # Resource for managing a kube-proxy
  class KubeProxy < Chef::Resource
    resource_name :kube_proxy

    property :version, String, default: '1.9.2'
    property :remote, String,
      default: lazy { |r|
        'https://storage.googleapis.com/kubernetes-release' \
        "/release/v#{r.version}/bin/linux/amd64/kube-proxy"
      }
    property :checksum, String,
      default: '27d1eba7d4b0c4a52e15c217b688ad0610e044357dfd8db81fe7fa8d41f2a895'
    property :file_ulimit, Integer, default: 65536

    action :create do
      remote_file "kube-proxy binary version: #{new_resource.version}" do
        path proxy_path
        mode '0755'
        source new_resource.remote
        checksum new_resource.checksum
      end
    end

    action :start do
      systemd_contents = {
        Unit: {
          Description: 'Kubernetes Kube-Proxy Server',
          Documentation: 'https://k8s.io',
          After: 'network.target',
        },
        Service: {
          ExecStart: generator.generate,
          Restart: 'on-failure',
          LimitNOFILE: new_resource.file_ulimit,
        },
        Install: {
          WantedBy: 'multi-user.target',
        },
      }

      systemd_unit 'kube-proxy.service' do
        content(systemd_contents)
        action :create
        notifies :restart, 'service[kube-proxy]', :immediately
      end

      service 'kube-proxy' do
        action %w(enable start)
      end
    end

    def generator
      CommandGenerator.new proxy_path, self
    end

    def proxy_path
      '/usr/sbin/kube-proxy'
    end
  end

  # Command line properties for the kube-proxy
  # Reference: https://kubernetes.io/docs/admin/kube-proxy/
  class KubeProxy
    property :azure_container_registry_config
    property :bind_address, default: '0.0.0.0'
    property :cleanup
    property :cleanup_ipvs, default: true
    property :cluster_cidr
    property :config
    property :config_sync_period, default: '15m0s'
    property :conntrack_max_per_core, default: 32_768
    property :conntrack_min, default: 131_072
    property :conntrack_tcp_timeout_close_wait, default: '1h0m0s'
    property :conntrack_tcp_timeout_established, default: '24h0m0s'
    property :feature_gates
    property :google_json_key
    property :healthz_bind_address, default: '0.0.0.0:10256'
    property :healthz_port, default: 10_249
    property :hostname_override
    property :iptables_masquerade_bit, default: 14
    property :iptables_min_sync_period
    property :iptables_sync_period, default: '30s'
    property :ipvs_min_sync_period
    property :ipvs_scheduler
    property :ipvs_sync_period, default: '30s'
    property :kube_api_burst, default: 10
    property :kube_api_content_type, default: 'application/vnd.kubernetes.protobuf'
    property :kube_api_qps, default: 5
    property :kubeconfig
    property :masquerade_all
    property :master, required: true
    property :metrics_bind_address, default: '127.0.0.1:10249'
    property :oom_score_adj, default: -999
    property :profiling
    property :proxy_mode
    property :proxy_port_range
    property :udp_timeout, default: '250ms'
    property :write_config_to

    property :v, default: 0
  end
end
