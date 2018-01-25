module KubernetesCookbook
  # Resource to manage a Kubernetes API server
  class KubeApiserver < Chef::Resource
    resource_name :kube_apiserver

    property :version, String, default: '1.9.2'
    property :remote, String,
      default: lazy { |r|
        'https://storage.googleapis.com/kubernetes-release' \
        "/release/v#{r.version}/bin/linux/amd64/kube-apiserver"
      }
    property :checksum, String,
      default: 'c9d5b3c84cc45fad82840192ba202f828494c83f525d6cf95e95d0ead4393daf'
    property :run_user, String, default: 'kubernetes'
    property :file_ulimit, Integer, default: 65536

    action :create do
      remote_file "kube-apiserver binary version: #{new_resource.version}" do
        path apiserver_path
        mode '0755'
        source new_resource.remote
        checksum new_resource.checksum
      end
    end

    action :start do
      user 'kubernetes' do
        action :create
        only_if { new_resource.run_user == 'kubernetes' }
      end

      directory '/var/run/kubernetes' do
        owner new_resource.run_user
      end

      template '/etc/tmpfiles.d/kubernetes.conf' do
        source 'systemd/tmpfiles.erb'
        cookbook 'kube'
      end

      systemd_contents = {
        Unit: {
          Description: 'Kubernetes API Server',
          Documentation: 'https://k8s.io',
          After: 'network.target',
        },
        Service: {
          Type: 'notify',
          User: new_resource.run_user,
          ExecStart: generator.generate,
          Restart: 'on-failure',
          LimitNOFILE: new_resource.file_ulimit,
        },
        Install: {
          WantedBy: 'multi-user.target',
        },
      }

      systemd_unit 'kube-apiserver.service' do
        content(systemd_contents)
        action :create
        notifies :restart, 'service[kube-apiserver]', :immediately
      end

      service 'kube-apiserver' do
        action %w(enable start)
      end
    end

    def generator
      CommandGenerator.new apiserver_path, self
    end

    def apiserver_path
      '/usr/sbin/kube-apiserver'
    end

    private

    def file_cache_path
      Chef::Config[:file_cache_path]
    end
  end

  # Commandline-related properties
  # Reference: https://kubernetes.io/docs/admin/kube-apiserver/
  class KubeApiserver
    property :admission_control, default: 'AlwaysAdmit'
    property :admission_control_config_file
    property :advertise_address
    property :allow_privileged, default: false
    property :anonymous_auth, default: true
    property :apiserver_count, default: 1
    property :audit_log_format, default: 'json'
    property :audit_log_maxage
    property :audit_log_maxbackup
    property :audit_log_maxsize
    property :audit_log_path
    property :audit_policy_file
    property :audit_webhook_batch_buffer_size, default: 10000
    property :audit_webhook_batch_initial_backoff, default: '10s'
    property :audit_webhook_batch_max_size, default: 400
    property :audit_webhook_batch_max_wait, '30s'
    property :audit_webhook_batch_throttle_burst, default: 15
    property :audit_webhook_batch_throttle_qps, default: 10
    property :audit_webhook_config_file
    property :audit_webhook_mode, default: 'batch'
    property :authentication_token_webhook_cache_ttl, default: '2m0s'
    property :authentication_token_webhook_config_file
    property :authorization_mode, default: 'AlwaysAllow'
    property :authorization_policy_file
    property :authorization_webhook_cache_authorized_ttl, default: '5m0s'
    property :authorization_webhook_cache_unauthorized_ttl, default: '30s'
    property :authorization_webhook_config_file
    property :azure_container_registry_config
    property :basic_auth_file
    property :bind_address, default: '0.0.0.0'
    property :cert_dir, default: '/var/run/kubernetes'
    property :client_ca_file
    property :cloud_config
    property :cloud_provider
    property :contention_profiling
    property :cors_allowed_origins, default: []
    property :default_watch_cache_size, default: 10
    property :delete_collection_workers, default: 1
    property :deserialization_cache_size
    property :enable_aggregator_routing
    property :enable_bootstrap_token_auth
    property :enable_garbage_collector, default: true
    property :enable_logs_handler, default: true
    property :enable_swagger_ui
    property :endpoint_reconciler_type, default: 'master-count'
    property :etcd_cafile
    property :etcd_certfile
    property :etcd_compaction_interval, default: '5m0s'
    property :etcd_keyfile
    property :etcd_prefix, default: '/registry'
    property :etcd_quorum_read
    property :etcd_servers, default: []
    property :etcd_servers_overrides, default: []
    property :event_ttl, default: '1h0m0s'
    property :experimental_encryption_provider_config
    property :experimental_keystone_ca_file
    property :experimental_keystone_url
    property :external_hostname
    property :feature_gates
    property :google_json_key
    property :insecure_bind_address, default: '127.0.0.1'
    property :insecure_port, default: 8080
    property :kubelet_certificate_authority
    property :kubelet_client_certificate
    property :kubelet_client_key
    property :kubelet_https, default: true
    property :kubelet_preferred_address_type, default: %w(Hostname InternalDNS InternalIP ExternalDNS ExternalIP)
    property :kubelet_read_only_port, default: 10_255
    property :kubelet_timeout, default: '5s'
    property :kubernetes_service_node_port
    property :master_service_namespace, default: 'default'
    property :max_connection_bytes_per_sec, default: 0
    property :max_mutating_requests_inflight, default: 200
    property :max_requests_inflight, default: 400
    property :min_request_timeout, default: 1800
    property :oidc_ca_file
    property :oidc_client_id
    property :oidc_groups_claim
    property :oidc_groups_prefix
    property :oidc_issuer_url
    property :oidc_username_claim, default: 'sub'
    property :oidc_username_prefix
    property :profiling, default: true
    property :proxy_client_cert_file
    property :proxy_client_key_file
    property :repair_malformed_updates, default: true
    property :requestheader_allowed_names
    property :requestheader_client_ca_file
    property :requestheader_extra_headers_prefix
    property :requestheader_group_headers
    property :requestheader_username_headers
    property :runtime_config
    property :secure_port, default: 6443
    property :service_account_key_file
    property :service_account_lookup, default: true
    property :service_cluster_ip_range
    property :service_node_port_range, default: '30000-32767'
    property :storage_backend
    property :storage_media_type, default: 'application/json'
    property :storage_versions
    property :target_ram_mb
    property :tls_ca_file
    property :tls_cert_file
    property :tls_private_key_file
    property :tls_sni_cert_key
    property :tls_private_key_file
    property :token_auth_file
    property :watch_cache, default: true
    property :watch_cache_sizes, default: []

    property :v, default: 0 # TODO: move to common class
  end
end
