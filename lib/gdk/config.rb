# frozen_string_literal: true

require 'cgi'
require 'etc'
require 'uri'
require 'pathname'

module GDK
  class Config < ConfigSettings
    GDK_ROOT = Pathname.new(__dir__).parent.parent
    FILE = File.join(GDK_ROOT, 'gdk.yml')

    string(:__platform) { GDK::Machine.platform }

    path(:__brew_prefix_path) do
      if GDK::Machine.macos?
        if File.exist?('/opt/homebrew/bin/brew')
          '/opt/homebrew'
        elsif File.exist?('/usr/local/bin/brew')
          '/usr/local'
        else
          ''
        end
      else
        ''
      end
    end

    path(:__openssl_bin_path) do
      if config.__brew_prefix_path.to_s.empty?
        Pathname.new(GDK::Dependencies.find_executable('openssl'))
      else
        config.__brew_prefix_path.join('opt', 'openssl@1.1', 'bin', 'openssl')
      end
    end

    path(:gdk_root) { self.class::GDK_ROOT }
    path(:__data_dir) { gdk_root.join('data') }
    path(:__cache_dir) { gdk_root.join('.cache') }
    integer(:restrict_cpu_count) { Etc.nprocessors }

    settings :common do
      string(:ca_path) { '' }
    end

    settings :repositories do
      string(:charts_gitlab) { 'https://gitlab.com/gitlab-org/charts/gitlab.git' }
      string(:gitaly) { 'https://gitlab.com/gitlab-org/gitaly.git' }
      string(:gitlab) { 'https://gitlab.com/gitlab-org/gitlab.git' }
      string(:gitlab_docs) { 'https://gitlab.com/gitlab-org/gitlab-docs.git' }
      string(:gitlab_elasticsearch_indexer) { 'https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer.git' }
      string(:gitlab_metrics_exporter) { 'https://gitlab.com/gitlab-org/gitlab-metrics-exporter.git' }
      string(:gitlab_k8s_agent) { 'https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent.git' }
      string(:gitlab_operator) { 'https://gitlab.com/gitlab-org/cloud-native/gitlab-operator.git' }
      string(:gitlab_pages) { 'https://gitlab.com/gitlab-org/gitlab-pages.git' }
      string(:gitlab_shell) { 'https://gitlab.com/gitlab-org/gitlab-shell.git' }
      string(:gitlab_spamcheck) { 'https://gitlab.com/gitlab-org/spamcheck.git' }
      string(:gitlab_runner) { 'https://gitlab.com/gitlab-org/gitlab-runner.git' }
      string(:gitlab_ui) { 'https://gitlab.com/gitlab-org/gitlab-ui.git' }
      string(:omnibus_gitlab) { 'https://gitlab.com/gitlab-org/omnibus-gitlab.git' }
    end

    settings :dev do
      path(:__go_path) { GDK.root.join('dev') }
      path(:__bins) { config.dev.__go_path.join('bin') }
      path(:__go_binary) { GDK::Dependencies.find_executable('go') }
      bool(:__go_binary_available?) do
        !config.dev.__go_binary.nil?
      rescue TypeError
        false
      end

      settings(:checkmake) do
        string(:version) { '8915bd4' }
        path(:__binary) { config.dev.__bins.join('checkmake') }
        path(:__versioned_binary) { config.dev.__bins.join("checkmake_#{config.dev.checkmake.version}") }
      end
    end

    array(:git_repositories) do
      # This list in not exhaustive yet, as some git repositories are based on
      # a fake GOPATH inside a projects sub directory
      %w[/ gitlab]
        .map { |d| File.join(gdk_root, d) }
        .select { |d| Dir.exist?(d) }
    end

    settings :gdk do
      bool(:ask_to_restart_after_update) { true }
      bool(:debug) { false }
      bool(:__debug) { ENV.fetch('GDK_DEBUG', 'false') == 'true' || config.gdk.debug? }
      integer(:runit_wait_secs) { 20 }
      bool(:quiet) { true }
      bool(:auto_reconfigure) { true }
      bool(:auto_rebase_projects) { false }
      bool(:use_bash_shim) { false }
      settings :experimental do
        bool(:quiet) { config.gdk.quiet? }
        bool(:auto_reconfigure) { config.gdk.auto_reconfigure? }
        bool(:ruby_services) { false }
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
        array(:before, merge: true) { ['support/exec-cd gitlab bin/spring stop || true'] }
        array(:after) { [] }
      end
    end

    path(:repositories_root) { config.gdk_root.join('repositories') }
    path(:repository_storages) { config.gdk_root.join('repository_storages') }

    string(:listen_address) { '127.0.0.1' }
    string(:hostname) { read!('hostname') || read!('host') || config.listen_address }
    port(:port, 'gdk') { read!('port') }

    settings :https do
      bool(:enabled) { read!('https_enabled') || false }
    end

    string :relative_url_root do
      read!('relative_url_root') || ''
    end

    anything :__uri do
      # Only include the port if it's 'non standard'
      klass = config.https? ? URI::HTTPS : URI::HTTP
      relative_url_root = config.relative_url_root.gsub(%r{/+$}, '')

      klass.build(host: config.hostname, port: config.port, path: relative_url_root)
    end

    string(:username) { Etc.getpwuid.name }
    string(:__whoami) { Etc.getpwuid.name }

    settings :load_balancing do
      bool(:enabled) { false }
      settings :discover do
        bool(:enabled) { false }
      end
    end

    settings :webpack do
      string(:host) { read!('webpack_host') || config.gitlab.rails.hostname }
      port(:port, 'webpack')
      string(:public_address) { "" }
      bool(:static) { false }
      bool(:vendor_dll) { false }
      bool(:incremental) { true }
      integer(:incremental_ttl) { 30 }
      bool(:sourcemaps) { true }
      bool(:live_reload) { true }

      string(:__dev_server_public) do
        if !config.webpack.live_reload
          ""
        elsif !config.webpack.public_address.empty?
          config.webpack.public_address
        elsif config.nginx?
          # webpack behind nginx
          if config.https?
            "wss://#{config.nginx.__listen_address}/_hmr/"
          else
            "ws://#{config.nginx.__listen_address}/_hmr/"
          end
        else
          ""
        end
      end
    end

    settings :action_cable do
      integer(:worker_pool_size) { 4 }
    end

    settings :workhorse do
      port(:configured_port, 'workhorse')

      settings :__listen_settings do
        string(:__type) do
          if config.gitlab.rails.address.empty?
            'authSocket'
          else
            'authBackend'
          end
        end

        string(:__address) do
          config.gitlab.rails.__workhorse_url
        end
      end

      string(:__active_host) { config.hostname }

      integer :__active_port do
        if config.nginx?
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

      string :__command_line_listen_addr do
        if config.https?
          "#{config.hostname}:0"
        else
          config.workhorse.__listen_address
        end
      end
    end

    settings :gitlab_shell do
      bool(:auto_update) { true }
      path(:dir) { config.gdk_root.join('gitlab-shell') }
    end

    settings :gitlab_ui do
      bool(:enabled) { false }
      bool(:auto_update) { true }
    end

    settings :rails_web do
      bool(:enabled) { true }
    end

    settings :gitlab_docs do
      bool(:enabled) { false }
      bool(:auto_update) { true }
      bool(:https) { false }
      port(:port, 'gitlab_docs')
      port(:port_https, 'gitlab_docs_https')

      anything :__uri do
        klass = config.gitlab_docs.https? ? URI::HTTPS : URI::HTTP
        port = config.gitlab_docs.https? ? config.gitlab_docs.port_https : config.gitlab_docs.port
        klass.build(host: config.hostname, port: port)
      end

      string(:__listen_address) { "#{config.nginx.listen}:#{config.gitlab_docs.port}" }
      string(:__https_listen_address) { "#{config.nginx.listen}:#{config.gitlab_docs.port_https}" }

      bool(:__all_configured?) { config.gitlab_docs.enabled? && config.gitlab_runner.enabled? && config.omnibus_gitlab.enabled? && config.charts_gitlab.enabled? && config.gitlab_operator.enabled? }

      string(:__nanoc_cmd_common) { "--host #{config.hostname} --port #{config.gitlab_docs.port}" }
      string(:__nanoc_live_cmd) { "../support/bundle-exec nanoc live #{config.gitlab_docs.__nanoc_cmd_common}" }
      string(:__nanoc_view_cmd) { "../support/bundle-exec nanoc compile && ../support/bundle-exec nanoc view #{config.gitlab_docs.__nanoc_cmd_common}" }
    end

    settings :snowplow_micro do
      bool(:enabled) { false }
      port(:port, 'snowplow_micro')
      string(:image) { 'snowplow/snowplow-micro:latest' }
    end

    settings :gitlab_spamcheck do
      bool(:enabled) { false }
      bool(:auto_update) { true }
      port(:port, 'gitlab_spamcheck')
      port(:external_port, 'gitlab_spamcheck_external')
      string(:output) { 'stdout' }
      bool(:monitor_mode) { false }
      string(:inspector_url) { "http://#{config.hostname}:8888/api/v1/isspam/issue" }
    end

    settings :gitlab_runner do
      bool(:enabled) { false }
      bool(:auto_update) { true }
    end

    settings :omnibus_gitlab do
      bool(:enabled) { false }
      bool(:auto_update) { true }
    end

    settings :charts_gitlab do
      bool(:enabled) { false }
      bool(:auto_update) { true }
    end

    settings :gitlab_operator do
      bool(:enabled) { false }
      bool(:auto_update) { true }
    end

    settings :gitlab_elasticsearch_indexer do
      bool(:auto_update) { true }
      path(:__dir) { config.gdk_root.join('gitlab-elasticsearch-indexer') }
    end

    settings :gitlab_metrics_exporter do
      bool(:auto_update) { true }
      bool(:enabled) { true }
      path(:dir) { config.gdk_root.join('gitlab-metrics-exporter') }
    end

    settings :registry do
      bool(:enabled) { read!('registry_enabled') || false }
      string(:host) { config.hostname }
      string(:listen_address) { config.listen_address }
      string(:api_host) { config.hostname }

      port(:port, 'registry') { read!('registry_port') }

      string(:__listen) { "#{host}:#{port}" }

      string :image do
        read!('registry_image') ||
          'registry.gitlab.com/gitlab-org/build/cng/gitlab-container-registry:' \
          'v3.49.0-gitlab'
      end

      bool(:self_signed) { false }
      bool(:auth_enabled) { true }

      string(:uid) { '' }
      string(:gid) { '' }

      bool(:compatibility_schema1_enabled) { false }
    end

    settings :object_store do
      bool(:consolidated_form) { false }
      bool(:enabled) { read!('object_store_enabled') || false }
      string(:host) { config.listen_address }
      port(:port, 'object_store') { read!('object_store') }
      port(:console_port, 'object_store_console')
      string(:backup_remote_directory) { '' }
      hash_setting(:connection) do
        {
          'provider' => 'AWS',
          'aws_access_key_id' => 'minio',
          'aws_secret_access_key' => 'gdk-minio',
          'region' => 'gdk',
          'endpoint' => "http://#{config.object_store.host}:#{config.object_store.port}",
          'path_style' => true
        }
      end
      hash_setting(:objects) do
        {
          'artifacts' => { 'bucket' => 'artifacts' },
          'external_diffs' => { 'bucket' => 'external-diffs' },
          'lfs' => { 'bucket' => 'lfs-objects' },
          'uploads' => { 'bucket' => 'uploads' },
          'packages' => { 'bucket' => 'packages' },
          'dependency_proxy' => { 'bucket' => 'dependency-proxy' },
          'terraform_state' => { 'bucket' => 'terraform' },
          'pages' => { 'bucket' => 'pages' }
        }
      end
    end

    settings :gitlab_pages do
      bool(:enabled) { false }
      string(:host) { "#{config.listen_address}.nip.io" }
      port(:port, 'gitlab_pages') { read!('gitlab_pages_port') }
      string(:__uri) { "#{config.gitlab_pages.host}:#{config.gitlab_pages.port}" }
      bool(:auto_update) { true }
      string(:secret_file) { config.gdk_root.join('gitlab-pages-secret') }
      bool(:verbose) { false }
      bool(:access_control) { false }
      string(:auth_client_id) { '' }
      string(:auth_client_secret) { '' }
      bool(:enable_custom_domains) { false }
      string(:auth_scope) { 'api' }
      # random 32-byte string
      string(:__auth_secret) { SecureRandom.alphanumeric(32) }
      string(:__auth_redirect_uri) { "http://#{config.gitlab_pages.__uri}/auth" }
    end

    settings :gitlab_k8s_agent do
      bool(:enabled) { false }
      bool(:auto_update) { true }

      string(:agent_listen_network) { 'tcp' }
      string(:agent_listen_address) { "#{config.listen_address}:8150" }
      string(:__agent_listen_url_path) { '/-/kubernetes-agent' }
      bool(:__agent_listen_websocket) do
        if config.nginx?
          # nginx's grpc_pass requires HTTP/2 enabled which requires TLS.
          # It's easier to use WebSockets than ask the user to generate
          # TLS certificates.
          true
        else
          false
        end
      end
      string(:__url_for_agentk) do
        if config.nginx?
          # kas is behind nginx
          if config.https?
            "wss://#{config.nginx.__listen_address}#{config.gitlab_k8s_agent.__agent_listen_url_path}"
          else
            "ws://#{config.nginx.__listen_address}#{config.gitlab_k8s_agent.__agent_listen_url_path}"
          end
        elsif config.gitlab_k8s_agent.agent_listen_network == 'tcp'
          "grpc://#{config.gitlab_k8s_agent.agent_listen_address}"
        else
          raise UnsupportedConfiguration, "Unsupported listen network #{config.gitlab_k8s_agent.agent_listen_network}"
        end
      end

      bool(:run_from_source) { false }

      string(:__command) do
        if config.gitlab_k8s_agent.run_from_source?
          'support/exec-cd gitlab-k8s-agent go run -race cmd/kas/main.go'
        else
          'gitlab-k8s-agent/build/gdk/bin/kas_race'
        end
      end

      string(:private_api_listen_network) { 'tcp' }
      string(:private_api_listen_address) { "#{config.listen_address}:8155" }
      string(:__private_api_secret_file) { config.gitlab_k8s_agent.__secret_file }
      string(:__private_api_url) { "grpc://#{config.gitlab_k8s_agent.private_api_listen_address}" }

      string(:k8s_api_listen_network) { 'tcp' }
      string(:k8s_api_listen_address) { "#{config.listen_address}:8154" }
      string(:__k8s_api_listen_url_path) { '/-/k8s-proxy/' }
      string(:__k8s_api_url) do
        if config.nginx?
          # kas is behind nginx
          if config.https?
            "https://#{config.nginx.__listen_address}#{config.gitlab_k8s_agent.__k8s_api_listen_url_path}"
          else
            "http://#{config.nginx.__listen_address}#{config.gitlab_k8s_agent.__k8s_api_listen_url_path}"
          end
        elsif config.gitlab_k8s_agent.k8s_api_listen_network == 'tcp'
          "http://#{config.gitlab_k8s_agent.k8s_api_listen_address}"
        else
          raise UnsupportedConfiguration, "Unsupported listen network #{config.gitlab_k8s_agent.k8s_api_listen_network}"
        end
      end

      string(:internal_api_listen_network) { 'tcp' }
      string(:internal_api_listen_address) { "#{config.listen_address}:8153" }
      string(:__internal_api_url) do
        case config.gitlab_k8s_agent.internal_api_listen_network
        when 'tcp'
          "grpc://#{internal_api_listen_address}"
        when 'unix'
          "unix://#{internal_api_listen_address}"
        else
          raise UnsupportedConfiguration, "Unsupported listen network #{config.gitlab_k8s_agent.internal_api_listen_network}"
        end
      end

      string(:__gitlab_address) { "#{config.https? ? 'https' : 'http'}://#{config.workhorse.__listen_address}" }
      string(:__config_file) { config.gdk_root.join('gitlab-k8s-agent-config.yml') }
      string(:__secret_file) { config.gdk_root.join('gitlab', '.gitlab_kas_secret') }

      string(:otlp_endpoint) { '' }
      string(:otlp_ca_certificate_file) { '' }
      string(:otlp_token_secret_file) { '' }
    end

    settings :omniauth do
      settings :google_oauth2 do
        string(:enabled) { client_secret }
        string(:client_id) { read!('google_oauth_client_id') || '' }
        string(:client_secret) { read!('google_oauth_client_secret') || '' }
      end
      settings :github do
        bool(:enabled) { false }
        string(:client_id) { '' }
        string(:client_secret) { '' }
      end
      settings :group_saml do
        bool(:enabled) { false }
      end
      settings :openid_connect do
        bool(:enabled) { false }
        # See https://docs.gitlab.com/ee/administration/auth/oidc.html for more detail
        hash_setting(:args) { {} }
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
      string(:version) { '8.5.3' }
      string(:__architecture) { GDK::Machine.architecture == 'arm64' ? 'aarch64' : GDK::Machine.architecture }
    end

    settings :tracer do
      string(:build_tags) { 'tracer_static tracer_static_jaeger' }
      settings :jaeger do
        bool(:enabled) { false }
        string(:version) { '1.21.0' }
        string(:listen_address) { config.hostname }
        string(:__tracer_url) do
          http_endpoint = "http://#{config.tracer.jaeger.listen_address}:14268/api/traces"

          "opentracing://jaeger?http_endpoint=#{CGI.escape(http_endpoint)}&sampler=const&sampler_param=1"
        end

        string(:__search_url) do
          tags = CGI.escape('{"correlation_id":"__CID__"}').gsub('__CID__', '{{ correlation_id }}')

          "http://#{config.tracer.jaeger.listen_address}:16686/search?service={{ service }}&tags=#{tags}"
        end
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
        port(:port, 'nginx')
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
      port(:port, 'postgresql') { read!('postgresql_port') }
      path(:bin_dir) { cmd!(%w[support/pg_bindir]) || '/usr/local/bin' }
      path(:bin) { config.postgresql.bin_dir.join('postgres') }
      string(:replication_user) { 'gitlab_replication' }
      path(:dir) { config.gdk_root.join('postgresql') }
      path(:data_dir) { config.postgresql.dir.join('data') }
      string(:host) { config.postgresql.dir.to_s }
      string(:active_version) { GDK::Postgresql.target_version.to_s }
      string(:__active_host) { GDK::Postgresql.new.use_tcp? ? config.postgresql.host : '' }

      # Kept for backward compatibility. Use replica:root_directory instead
      path(:replica_dir) { config.gdk_root.join('postgresql-replica') }
      # Kept for backward compatibility. Use replica:data_directory instead
      path(:replica_data_dir) { config.postgresql.replica_dir.join('data') }

      settings :replica do
        bool(:enabled) { false }
        path(:root_directory) { config.postgresql.replica_dir } # fallback to config.postgresql.replica_dir for backward compatibility
        path(:data_directory) { config.postgresql.replica_data_dir } # fallback to config.postgresql.replica_data_dir for backward compatibility
        string(:host) { root_directory.to_s }
        port(:port1, 'pgbouncer_replica-1')
        port(:port2, 'pgbouncer_replica-2')
      end

      settings :replica_2 do
        bool(:enabled) { false }
        path(:root_directory) { config.gdk_root.join('postgresql-replica-2') }
        path(:data_directory) { root_directory.join('data') }
        string(:host) { root_directory.to_s }
        port(:port1, 'pgbouncer_replica-2-1')
        port(:port2, 'pgbouncer_replica-2-2')
      end

      settings :multiple_replicas do
        bool(:enabled) { false }
      end
      settings :geo do
        port(:port, 'postgresql_geo')
        path(:dir) { config.gdk_root.join('postgresql-geo') }
        string(:host) { config.postgresql.geo.dir.to_s }
        string(:__active_host) { GDK::PostgresqlGeo.new.use_tcp? ? config.postgresql.geo.host : '' }
      end
    end

    settings :pgbouncer_replicas do
      bool(:enabled) { false }
    end

    settings :clickhouse do
      bool(:enabled) { false }
      path(:bin) { find_executable!('clickhouse') || '/usr/bin/clickhouse' }
      path(:dir) { config.gdk_root.join('clickhouse') }
      path(:data_dir) { config.clickhouse.dir.join('data') }
      path(:log_dir) { config.gdk_root.join('log', 'clickhouse') }
      string(:log_level) { 'trace' }
      port(:http_port, 'clickhouse_http')
      port(:tcp_port, 'clickhouse_tcp')
      port(:interserver_http_port, 'clickhouse_interserver')
      integer(:max_memory_usage) { 1000 * 1000 * 1000 } # 1 GB
      integer(:max_thread_pool_size) { 1000 }
      integer(:max_server_memory_usage) { 2 * 1000 * 1000 * 1000 } # 2 GB
    end

    settings :gitaly do
      path(:dir) { config.gdk_root.join('gitaly') }
      path(:ruby_dir) { config.gitaly.dir.join('ruby') }
      bool(:enabled) { !config.praefect? || storage_count > 1 }
      path(:address) { config.gdk_root.join('gitaly.socket') }
      path(:assembly_dir) { config.gitaly.dir.join('assembly') }
      path(:config_file) { config.gitaly.dir.join('gitaly.config.toml') }
      path(:log_dir) { config.gdk_root.join('log', 'gitaly') }
      path(:storage_dir) { config.repositories_root }
      path(:repository_storages) { config.repository_storages }
      path(:runtime_dir) { config.gdk_root.join('tmp') }
      string(:auth_token) { '' }
      bool(:auto_update) { true }
      bool(:enable_all_feature_flags) { false }
      integer(:storage_count) { 1 }
      path(:__build_path) { config.gitaly.dir.join('_build') }
      path(:__build_bin_path) { config.gitaly.__build_path.join('bin') }
      path(:__build_bin_backup_path) { config.gitaly.__build_bin_path.join('gitaly-backup') }
      path(:__gitaly_build_bin_path) { config.gitaly.__build_bin_path.join('gitaly') }
      array(:gitconfig) { [] }
      settings_array :__storages, size: -> { storage_count } do |i|
        string(:name) { i.zero? ? 'default' : "gitaly-#{i}" }
        path(:path) do
          if i.zero?
            parent.parent.storage_dir
          else
            File.join(config.repository_storages, 'gitaly', name)
          end
        end
      end
    end

    settings :praefect do
      path(:address) { config.gdk_root.join('praefect.socket') }
      path(:config_file) { config.gitaly.dir.join('praefect.config.toml') }
      bool(:enabled) { true }
      path(:__praefect_build_bin_path) { config.gitaly.__build_bin_path.join('praefect') }
      settings :database do
        string(:host) { config.geo.secondary? ? config.postgresql.geo.host : config.postgresql.host }
        integer(:port) { config.geo.secondary? ? config.postgresql.geo.port : config.postgresql.port }
        string(:dbname) { 'praefect_development' }
        string(:sslmode) { 'disable' }
      end
      integer(:node_count) { 1 }
      settings_array :__nodes, size: -> { config.praefect.node_count } do |i|
        path(:address) { config.gdk_root.join("gitaly-praefect-#{i}.socket") }
        string(:config_file) { "gitaly/gitaly-#{i}.praefect.toml" }
        path(:log_dir) { config.gdk_root.join('log', "praefect-gitaly-#{i}") }
        string(:service_name) { "praefect-gitaly-#{i}" }
        string(:storage) { "praefect-internal-#{i}" }
        path(:storage_dir) { config.repositories_root }
        path(:repository_storages) { config.repository_storages }
        path(:runtime_dir) { config.gdk_root.join('tmp') }
        array(:gitconfig) { [] }
        settings_array :__storages, size: 1 do |j|
          string(:name) { parent.parent.storage }
          path(:path) { i.zero? && j.zero? ? parent.parent.storage_dir : File.join(parent.parent.repository_storages, parent.parent.service_name, name) }
        end
      end
    end

    settings :sshd do
      string(:__full_command) do
        if config.sshd.use_gitlab_sshd?
          "#{config.gitlab_shell.dir}/bin/gitlab-sshd -config-dir #{config.gitlab_shell.dir}"
        else
          "#{config.sshd.bin} -e -D -f #{config.gdk_root.join('openssh', 'sshd_config')}"
        end
      end

      string(:__log_file) do
        if config.sshd.use_gitlab_sshd?
          "/dev/stdout"
        else
          "#{config.gitlab_shell.dir}/gitlab-shell.log"
        end
      end

      string(:__listen) do
        host = config.sshd.listen_address
        host = "[#{host}]" if host.include?(':')

        "#{host}:#{config.sshd.listen_port}"
      end

      bool(:enabled) { true }
      bool(:use_gitlab_sshd) { true }
      string(:listen_address) { config.hostname }
      port(:listen_port, 'sshd')
      string(:user) do
        if config.sshd.use_gitlab_sshd?
          'git'
        else
          config.username
        end
      end
      anything(:host_key) { '' } # kept for backward compatibility in case the user did set this
      array(:host_key_algorithms) { %w[rsa ed25519] }
      array(:host_keys) do
        host_key_algorithms.map { |algorithm| config.gdk_root.join('openssh', "ssh_host_#{algorithm}_key").to_s }
          .append(host_key)
          .reject(&:empty?).uniq
      end

      # gitlab-sshd only
      bool(:proxy_protocol) { false }
      string(:web_listen) { "#{config.listen_address}:9122" }

      # OpenSSH only
      path(:bin) { find_executable!('sshd') || '/usr/local/sbin/sshd' }
      string(:additional_config) { '' }
      path(:authorized_keys_file) { config.gdk_root.join('.ssh', 'authorized_keys') }
    end

    settings :git do
      path(:bin) { find_executable!('git') || '/usr/local/bin/git' }
    end

    settings :runner do
      path(:config_file) { config.gdk_root.join('gitlab-runner-config.toml') }
      bool(:enabled) { config_file.exist? }
      string(:install_mode) { "binary" }
      string(:executor) { "docker" }
      array(:extra_hosts) { [] }
      string(:token) { 'DEFAULT TOKEN: Register your runner to get a valid token' }
      string(:image) { "gitlab/gitlab-runner:latest" }
      string(:pull_policy) { "if-not-present" }
      path(:bin) { find_executable!('gitlab-runner') || '/usr/local/bin/gitlab-runner' }
      bool(:network_mode_host) { false }
      bool(:__network_mode_host) do
        raise UnsupportedConfiguration, 'runner.network_mode_host is only supported on Linux' if config.runner.network_mode_host && !GDK::Machine.linux?

        config.runner.network_mode_host
      end
      bool(:__install_mode_binary) { config.runner? && config.runner.install_mode == "binary" }
      bool(:__install_mode_docker) { config.runner? && config.runner.install_mode == "docker" }
      string(:__ssl_certificate) { Pathname.new(File.basename(config.nginx.ssl.certificate)).sub_ext('.crt') }
      string(:__add_host_flags) { config.runner.extra_hosts.map { |h| "--add-host='#{h}'" }.join(" ") }
    end

    settings :grafana do
      bool(:enabled) { false }
      port(:port, 'grafana')
      anything(:__uri) { URI::HTTP.build(host: config.hostname, port: port) }
    end

    settings :prometheus do
      bool(:enabled) { false }
      port(:port, 'prometheus')
      anything(:__uri) { URI::HTTP.build(host: config.hostname, port: port) }
      port(:gitaly_exporter_port, 'gitaly_exporter')
      port(:praefect_exporter_port, 'praefect_exporter')
      port(:workhorse_exporter_port, 'workhorse_exporter')
      port(:gitlab_shell_exporter_port, 'gitlab_shell_exporter')
    end

    settings :openldap do
      bool(:enabled) { false }
    end

    settings :mattermost do
      bool(:enabled) { false }
      port(:port, 'mattermost')
      string(:image) { 'mattermost/mattermost-preview' }
    end

    settings :vault do
      bool(:enabled) { false }
      string(:__listen) { "#{listen_address}:#{port}" }
      port(:port, 'vault')
      string(:listen_address) { config.listen_address }
    end

    settings :gitlab do
      bool(:auto_update) { true }
      bool(:lefthook_enabled) { true }
      path(:dir) { config.gdk_root.join('gitlab') }
      path(:log_dir) { config.gitlab.dir.join('log') }
      bool(:cache_classes) { false }
      bool(:gitaly_disable_request_limits) { false }

      settings :rails do
        string(:hostname) { config.hostname }
        integer(:port) { config.port }

        settings :https do
          bool(:enabled) { config.https? }
        end

        bool(:bootsnap) { true }
        string(:address) { '' }
        string(:__bind) { "#{config.gitlab.rails.__listen_settings.__protocol}://#{config.gitlab.rails.__listen_settings.__address}" }
        string(:__workhorse_url) do
          if config.gitlab.rails.address.empty?
            config.gitlab.rails.__socket_file
          else
            "http://#{config.gitlab.rails.__listen_settings.__address}"
          end
        end
        path(:__socket_file) { config.gdk_root.join('gitlab.socket') }
        string(:__socket_file_escaped) { CGI.escape(config.gitlab.rails.__socket_file.to_s) }

        settings :__listen_settings do
          string(:__protocol) do
            if config.gitlab.rails.address.empty?
              'unix'
            else
              'tcp'
            end
          end

          string(:__address) do
            if config.gitlab.rails.address.empty?
              config.gitlab.rails.__socket_file
            else
              config.gitlab.rails.address
            end
          end
        end

        bool(:__has_jh_dir) { File.exist?(config.gitlab.dir.join('jh')) }

        string(:bundle_gemfile) do
          if __has_jh_dir
            config.gitlab.dir.join('jh/Gemfile')
          else
            config.gitlab.dir.join('Gemfile')
          end
        end

        # Deprecated, use :databases settings instead
        bool(:multiple_databases) { false }

        settings :databases do
          settings :ci do
            bool(:enabled) { true }
            bool(:use_main_database) { false }

            bool(:__enabled) do
              config.gitlab.rails.multiple_databases || config.gitlab.rails.databases.ci.enabled
            end

            bool(:__use_main_database) do
              if config.gitlab.rails.multiple_databases
                false
              elsif config.gitlab.rails.databases.ci.enabled
                config.gitlab.rails.databases.ci.use_main_database
              else
                false
              end
            end
          end
        end

        settings :puma do
          integer(:workers) { 2 }

          integer(:threads_max) { 4 }
          integer(:__threads_max) { config.gitlab.rails.puma.__threads_min > config.gitlab.rails.puma.threads_max ? config.gitlab.rails.puma.__threads_min : config.gitlab.rails.puma.threads_max }
          integer(:threads_min) { 1 }
          integer(:__threads_min) { config.gitlab.rails.puma.workers.zero? ? config.gitlab.rails.puma.threads_max : config.gitlab.rails.puma.threads_min }
        end
      end

      settings :rails_background_jobs do
        bool(:verbose) { false }
        integer(:timeout) { config.gdk.runit_wait_secs / 2 }
        bool(:sidekiq_exporter_enabled) { false }
        port(:sidekiq_exporter_port, 'sidekiq_exporter')
        bool(:sidekiq_health_check_enabled) { false }
        port(:sidekiq_health_check_port, 'sidekiq_health_check')
      end
    end

    settings :redis do
      path(:dir) { config.gdk_root.join('redis') }
      path(:__socket_file) { dir.join('redis.socket') }

      settings(:databases) do
        settings(:development) do
          integer(:shared_state) { 0 } # This inherits db=0 for compatibility reaons
          integer(:queues) { 1 }
          integer(:cache) { 2 }
          integer(:repository_cache) { 2 }
          integer(:trace_chunks) { 3 }
          integer(:rate_limiting) { 4 }
          integer(:sessions) { 5 }
        end

        settings(:test) do
          integer(:shared_state) { 10 }
          integer(:queues) { 11 }
          integer(:cache) { 12 }
          integer(:repository_cache) { 12 }
          integer(:trace_chunks) { 13 }
          integer(:rate_limiting) { 14 }
          integer(:sessions) { 15 }
        end
      end

      # See doc/howto/redis.md for more detail
      hash_setting(:custom_config) { {} }
    end

    settings :asdf do
      bool(:opt_out) { false }
      bool(:__available?) { !config.asdf.opt_out? && ENV.values_at('ASDF_DATA_DIR', 'ASDF_DIR').compact.any? }
    end

    settings :packages do
      path(:__dpkg_deb_path) do
        if GDK::Machine.macos?
          config.__brew_prefix_path.join('bin', 'dpkg-deb')
        else
          '/usr/bin/dpkg-deb'
        end
      end
    end
  end
end
