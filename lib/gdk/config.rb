# frozen_string_literal: true

require 'cgi'
require 'etc'
require 'uri'
require_relative 'config_settings'

module GDK
  class Config < ConfigSettings
    GDK_ROOT = Pathname.new(__dir__).parent.parent
    FILE = File.join(GDK_ROOT, 'gdk.yml')

    string(:__architecture) { RbConfig::CONFIG['target_cpu'] }
    string(:__platform) do
      case RbConfig::CONFIG['host_os']
      when /darwin/i
        'macos'
      when /linux/i
        'linux'
      else
        'unknown'
      end
    end

    settings :common do
      string(:ca_path) { '' }
    end

    settings :repositories do
      string(:gitlab) { 'https://gitlab.com/gitlab-org/gitlab.git' }
      string(:gitlab_shell) { 'https://gitlab.com/gitlab-org/gitlab-shell.git' }
      string(:gitlab_workhorse) { 'https://gitlab.com/gitlab-org/gitlab-workhorse.git' }
      string(:gitaly) { 'https://gitlab.com/gitlab-org/gitaly.git' }
      string(:gitlab_pages) { 'https://gitlab.com/gitlab-org/gitlab-pages.git' }
      string(:gitlab_k8s_agent) { 'https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent.git' }
      string(:gitlab_docs) { 'https://gitlab.com/gitlab-com/gitlab-docs.git' }
      string(:gitlab_elasticsearch_indexer) { 'https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer.git' }
    end

    array(:git_repositories) do
      # This list in not exhaustive yet, as some git repositories are based on
      # a fake GOPATH inside a projects sub directory
      %w[/ gitlab]
        .map { |d| File.join(gdk_root, d) }
        .select { |d| Dir.exist?(d) }
    end

    path(:gdk_root) { self.class::GDK_ROOT }

    settings :gdk do
      bool(:ask_to_restart_after_update) { true }
      bool(:debug) { false }
      integer(:runit_wait_secs) { 10 }
      settings :experimental do
        bool(:quiet) { false }
        bool(:auto_reconfigure) { false }
      end
      bool(:overwrite_changes) { false }
      array(:protected_config_files) { [] }
      settings :start_hooks do
        array(:before) { [] }
        array(:after) { [] }
      end
      settings :stop_hooks do
        array(:before) { [] }
        array(:after) { [] }
      end
      settings :update_hooks do
        array(:before) { [] }
        array(:after) { [] }
      end
    end

    path(:repositories_root) { config.gdk_root.join('repositories') }
    path(:repository_storages) { config.gdk_root.join('repository_storages') }

    string(:listen_address) { '127.0.0.1' }

    string :hostname do
      next "#{config.auto_devops.gitlab.port}.qa-tunnel.gitlab.info" if config.auto_devops?

      read!('hostname') || read!('host') || config.listen_address
    end

    integer :port do
      next 443 if config.auto_devops?

      read!('port') || 3000
    end

    settings :https do
      bool :enabled do
        next true if config.auto_devops?

        read!('https_enabled') || false
      end
    end

    string :relative_url_root do
      read!('relative_url_root') || '/'
    end

    anything :__uri do
      # Only include the port if it's 'non standard'
      klass = config.https? ? URI::HTTPS : URI::HTTP
      relative_url_root = config.relative_url_root.gsub(%r{/+$}, '')

      klass.build(host: config.hostname, port: config.port, path: relative_url_root)
    end

    string(:username) { Etc.getpwuid.name }

    settings :load_balancing do
      bool(:enabled) { false }
    end

    settings :webpack do
      string :host do
        next config.auto_devops.listen_address if config.auto_devops?

        read!('webpack_host') || config.hostname
      end
      bool(:static) { false }
      bool(:vendor_dll) { false }
      bool(:sourcemaps) { true }
      bool(:live_reload) { !config.https? }

      integer(:port) { read!('webpack_port') || 3808 }
    end

    settings :action_cable do
      bool(:in_app) { true }
      integer(:worker_pool_size) { 4 }
    end

    settings :workhorse do
      integer(:configured_port) { 3333 }

      settings :listen_settings do
        string(:type) do
          if config.gitlab.rails.address.empty?
            'authSocket'
          else
            'authBackend'
          end
        end

        string(:address) do
          if config.gitlab.rails.address.empty?
            config.gitlab.rails.__socket_file
          else
            "http://#{config.gitlab.rails.address}"
          end
        end
      end

      string :__active_host do
        next config.auto_devops.listen_address if config.auto_devops?

        config.hostname
      end

      integer :__active_port do
        if config.auto_devops? || config.nginx?
          config.workhorse.configured_port
        else
          # Workhorse is the user-facing entry point whenever neither nginx nor
          # AutoDevOps is used, so in that situation use the configured GDK port.
          config.port
        end
      end

      string :__listen_address do
        "#{config.workhorse.__active_host}:#{config.workhorse.__active_port}"
      end

      bool(:auto_update) { true }
    end

    settings :gitlab_shell do
      bool(:auto_update) { true }
      string(:dir) { config.gdk_root.join('gitlab-shell') }
    end

    settings :gitlab_elasticsearch_indexer do
      bool(:auto_update) { true }
      path(:__dir) { config.gdk_root.join('gitlab-elasticsearch-indexer') }
    end

    settings :registry do
      bool :enabled do
        next true if config.auto_devops?

        read!('registry_enabled') || false
      end

      string :host do
        next "#{config.auto_devops.registry.port}.qa-tunnel.gitlab.info" if config.auto_devops?

        config.hostname
      end

      string :listen_address do
        config.listen_address
      end

      string :api_host do
        next config.listen_address if config.auto_devops?

        config.hostname
      end

      string :tunnel_host do
        next config.listen_address if config.auto_devops?

        config.hostname
      end

      integer(:tunnel_port) { 5000 }

      integer :port do
        read!('registry_port') || 5000
      end

      string :image do
        read!('registry_image') ||
          'registry.gitlab.com/gitlab-org/build/cng/gitlab-container-registry:'\
        'v2.9.1-gitlab'
      end

      integer :external_port do
        next 443 if config.auto_devops?

        5000
      end

      bool(:self_signed) { false }
      bool(:auth_enabled) { true }
    end

    settings :object_store do
      bool(:consolidated_form) { false }
      bool(:enabled) { read!('object_store_enabled') || false }
      string(:host) { config.listen_address }
      integer(:port) { read!('object_store_port') || 9000 }
      hash(:connection) do
        {
          'provider' => 'AWS',
          'aws_access_key_id' => 'minio',
          'aws_secret_access_key' => 'gdk-minio',
          'region' => 'gdk',
          'endpoint' => "http://#{config.object_store.host}:#{config.object_store.port}",
          'path_style' => true
        }
      end
      hash(:objects) do
        {
          'artifacts' => { 'bucket' => 'artifacts' },
          'external_diffs' => { 'bucket' => 'external-diffs' },
          'lfs' => { 'bucket' => 'lfs-objects' },
          'uploads' => { 'bucket' => 'uploads' },
          'packages' => { 'bucket' => 'packages' },
          'dependency_proxy' => { 'bucket' => 'dependency_proxy' },
          'terraform_state' => { 'bucket' => 'terraform' },
          'pages' => { 'bucket' => 'pages' }
        }
      end
    end

    settings :gitlab_pages do
      bool(:enabled) { true }
      string(:host) { "#{config.listen_address}.nip.io" }
      integer(:port) { read!('gitlab_pages_port') || 3010 }
      string(:__uri) { "#{config.gitlab_pages.host}:#{config.gitlab_pages.port}" }
      bool(:auto_update) { true }
      string(:secret_file) { config.gdk_root.join('gitlab-pages-secret') }
      bool(:verbose) { false }
    end

    settings :gitlab_k8s_agent do
      bool(:enabled) { false }
      bool(:auto_update) { true }
      string(:listen_network) { 'tcp' }
      string(:listen_address) { "#{config.listen_address}:8150" }
      string(:__listen_url_path) { '/-/kubernetes-agent' }
      string(:__gitlab_address) { "http://#{config.workhorse.__listen_address}" }
      string :__url_for_agentk do
        if config.nginx?
          # kas is behind nginx
          if config.https?
            "wss://#{config.nginx.__listen_address}#{config.gitlab_k8s_agent.__listen_url_path}"
          else
            "ws://#{config.nginx.__listen_address}#{config.gitlab_k8s_agent.__listen_url_path}"
          end
        elsif config.gitlab_k8s_agent.listen_network == 'tcp'
          "grpc://#{config.gitlab_k8s_agent.listen_address}"
        else
          raise "Unsupported listen network #{config.gitlab_k8s_agent.listen_network}"
        end
      end
      bool :__listen_websocket do
        if config.nginx?
          # nginx's grpc_pass requires HTTP/2 enabled which requires TLS.
          # It's easier to use WebSockets than ask the user to generate
          # TLS certificates.
          true
        else
          false
        end
      end
      string(:__config_file) { config.gdk_root.join('gitlab-k8s-agent-config.yml') }
      string(:__secret_file) { config.gdk_root.join('gitlab', '.gitlab_kas_secret') }
    end

    settings :auto_devops do
      bool(:enabled) { read!('auto_devops_enabled') || false }
      string(:listen_address) { '0.0.0.0' }
      settings :gitlab do
        integer(:port) { read_or_write!('auto_devops_gitlab_port', rand(20_000..24_999)) }
      end
      settings :registry do
        integer(:port) { read!('auto_devops_registry_port') || (config.auto_devops.gitlab.port + 5000) }
      end
    end

    settings :omniauth do
      settings :google_oauth2 do
        string(:enabled) { !!read!('google_oauth_client_secret') || '' }
        string(:client_id) { read!('google_oauth_client_id') || '' }
        string(:client_secret) { read!('google_oauth_client_secret') || '' }
      end
      settings :group_saml do
        bool(:enabled) { false }
      end
    end

    settings :geo do
      bool(:enabled) { false }
      bool(:secondary) { false }
      string(:node_name) { config.gdk_root.basename.to_s }
      settings :registry_replication do
        bool(:enabled) { false }
        string(:primary_api_url) { 'http://localhost:5000' }
      end
    end

    settings :elasticsearch do
      bool(:enabled) { false }
      string(:version) { '7.9.2' }
      string(:mac_checksum) { '34677a23e818abe4eb81fc8b052351bf4695765a1fbef12acad7ec9ddfe89da3f31ec44969ce136e1c7033d2c32558780c787a1cae82ed99537367bb8266567c' }
      string(:linux_checksum) { 'bbd0b012194f8dfb911e75a355f3a23d8aebee58a748d8010558c969ada706e61340b3e66b16a13788ae772d9e8da2e26a35cfbfa14a04d718fb8a992d661518' }
    end

    settings :tracer do
      string(:build_tags) { 'tracer_static tracer_static_jaeger' }
      settings :jaeger do
        bool(:enabled) { true }
        string(:version) { '1.10.1' }
      end
    end

    settings :nginx do
      bool(:enabled) { false }
      string(:listen) { config.hostname }
      string(:bin) { find_executable!('nginx') || '/usr/local/bin/nginx' }
      settings :ssl do
        string(:certificate) { 'localhost.crt' }
        string(:key) { 'localhost.key' }
      end
      settings :http do
        bool(:enabled) { false }
        integer(:port) { 8080 }
      end
      settings :http2 do
        bool(:enabled) { false }
      end
      string(:__listen_address) { "#{config.nginx.listen}:#{config.port}" }
      array(:__request_buffering_off_routes) do
        [
          '/api/v\d/jobs/\d+/artifacts$',
          '\.git/git-receive-pack$',
          '\.git/gitlab-lfs/objects',
          '\.git/info/lfs/objects/batch$'
        ]
      end
    end

    settings :postgresql do
      integer(:port) { read!('postgresql_port') || 5432 }
      path(:bin_dir) { cmd!(%w[support/pg_bindir]) || '/usr/local/bin' }
      path(:bin) { config.postgresql.bin_dir.join('postgres') }
      string(:replication_user) { 'gitlab_replication' }
      path(:dir) { config.gdk_root.join('postgresql') }
      path(:data_dir) { config.postgresql.dir.join('data') }
      string(:host) { config.postgresql.dir.to_s }
      string(:__active_host) { GDK::Postgresql.new.use_tcp? ? config.postgresql.host : '' }
      path(:replica_dir) { config.gdk_root.join('postgresql-replica') }
      settings :replica do
        bool(:enabled) { false }
      end
      settings :geo do
        integer(:port) { 5431 }
        path(:dir) { config.gdk_root.join('postgresql-geo') }
        string(:host) { config.postgresql.geo.dir.to_s }
        string(:__active_host) { GDK::PostgresqlGeo.new.use_tcp? ? config.postgresql.geo.host : '' }
      end
    end

    settings :gitaly do
      bool(:enabled) { !config.praefect? || __storages.length > 1 }
      path(:address) { config.gdk_root.join('gitaly.socket') }
      path(:assembly_dir) { config.gdk_root.join('gitaly', 'assembly') }
      path(:config_file) { config.gdk_root.join('gitaly', 'gitaly.config.toml') }
      path(:log_dir) { config.gdk_root.join('log', 'gitaly') }
      path(:storage_dir) { config.repositories_root }
      path(:repository_storages) { config.repository_storages }
      path(:internal_socket_dir) { config.gdk_root.join('tmp', 'gitaly') }
      string(:auth_token) { '' }
      bool(:auto_update) { true }
      integer(:storage_count) { 1 }
      array(:__storages) do
        settings_array!(storage_count) do |i|
          string(:name) { i.zero? ? 'default' : "gitaly-#{i}" }
          path(:path) do
            if i.zero?
              parent.storage_dir
            else
              File.join(config.repository_storages, 'gitaly', name)
            end
          end
        end
      end
    end

    settings :praefect do
      path(:address) { config.gdk_root.join('praefect.socket') }
      path(:config_file) { config.gdk_root.join('gitaly', 'praefect.config.toml') }
      bool(:enabled) { true }
      path(:internal_socket_dir) { config.gdk_root.join('tmp', 'praefect') }
      settings :database do
        string(:host) { config.geo.secondary? ? config.postgresql.geo.host : config.postgresql.host }
        integer(:port) { config.geo.secondary? ? config.postgresql.geo.port : config.postgresql.port }
        string(:dbname) { 'praefect_development' }
        string(:sslmode) { 'disable' }
      end
      integer(:node_count) { 1 }
      array(:__nodes) do
        settings_array!(config.praefect.node_count) do |i|
          path(:address) { config.gdk_root.join("gitaly-praefect-#{i}.socket") }
          string(:config_file) { "gitaly/gitaly-#{i}.praefect.toml" }
          path(:log_dir) { config.gdk_root.join('log', "praefect-gitaly-#{i}") }
          string(:service_name) { "praefect-gitaly-#{i}" }
          string(:storage) { "praefect-internal-#{i}" }
          path(:storage_dir) { config.repositories_root }
          path(:repository_storages) { config.repository_storages }
          path(:internal_socket_dir) { config.gdk_root.join('tmp', 'praefect', "gitaly-#{i}") }
          array(:__storages) do
            settings_array!(1) do |j|
              string(:name) { parent.storage }
              path(:path) { i.zero? && j.zero? ? parent.storage_dir : File.join(parent.repository_storages, parent.service_name, name) }
            end
          end
        end
      end
    end

    settings :sshd do
      bool(:enabled) { false }
      path(:bin) { find_executable!('sshd') || '/usr/local/sbin/sshd' }
      string(:listen_address) { config.hostname }
      integer(:listen_port) { 2222 }
      string(:user) { config.username }
      path(:authorized_keys_file) { config.gdk_root.join('.ssh', 'authorized_keys') }
      path(:host_key) { config.gdk_root.join('openssh', 'ssh_host_rsa_key') }
      string(:additional_config) { '' }
    end

    settings :git do
      path(:bin) { find_executable!('git') || '/usr/local/bin/git' }
    end

    settings :runner do
      path(:config_file) { config.gdk_root.join('gitlab-runner-config.toml') }
      bool(:enabled) { !!read!(config.runner.config_file) }
      array(:extra_hosts) { [] }
      string(:token) { 'DEFAULT TOKEN: Register your runner to get a valid token' }
      path(:bin) { find_executable!('gitlab-runner') || '/usr/local/bin/gitlab-runner' }
    end

    settings :grafana do
      bool(:enabled) { false }
    end

    settings :prometheus do
      bool(:enabled) { false }
      integer(:port) { 9090 }
      integer(:gitaly_exporter_port) { 9236 }
      integer(:praefect_exporter_port) { 10_101 }
      integer(:sidekiq_exporter_port) { 3807 }
    end

    settings :openldap do
      bool(:enabled) { false }
    end

    settings :mattermost do
      bool(:enabled) { false }
      integer(:port) { config.auto_devops.gitlab.port + 7000 }
      string(:image) { 'mattermost/mattermost-preview' }
      integer(:local_port) { 8065 }
    end

    settings :gitlab do
      path(:dir) { config.gdk_root.join('gitlab') }
      bool(:cache_classes) { false }

      settings :rails do
        string(:address) { '' }
        path(:__socket_file) { config.gdk_root.join('gitlab.socket') }
        string(:__socket_file_escaped) { CGI.escape(config.gitlab.rails.__socket_file.to_s) }

        settings :listen_settings do
          string(:protocol) do
            if config.gitlab.rails.address.empty?
              'unix'
            else
              'tcp'
            end
          end

          string(:address) do
            if config.gitlab.rails.address.empty?
              config.gitlab.rails.__socket_file
            else
              config.gitlab.rails.address
            end
          end
        end
      end

      settings :actioncable do
        path(:__socket_file) do
          if config.action_cable.in_app?
            config.gdk_root.join('gitlab.socket')
          else
            config.gdk_root.join('gitlab.actioncable.socket')
          end
        end
      end
    end
  end
end
