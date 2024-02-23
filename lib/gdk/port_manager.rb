# frozen_string_literal: true

require 'socket'
require 'timeout'

require_relative '../gdk'

module GDK
  class PortManager
    ServiceUnknownError = Class.new(StandardError)
    PortAlreadyAllocated = Class.new(StandardErrorWithMessage)
    PortInUseError = Class.new(StandardError)

    DEFAULT_PORTS_FOR_SERVICES = {
      2222 => 'sshd',
      3000 => 'gdk',
      3005 => 'gitlab_docs',
      3010 => 'gitlab_pages',
      3030 => 'gitlab_docs_https',
      3038 => 'vite',
      3333 => 'workhorse',
      3444 => 'smartcard_nginx',
      3807 => 'sidekiq_exporter',
      3808 => 'webpack',
      3907 => 'sidekiq_health_check',
      4000 => 'grafana',
      5000 => 'registry',
      5431 => 'postgresql_geo',
      5432 => 'postgresql',
      6000 => 'redis_cluster_dev_1',
      6001 => 'redis_cluster_dev_2',
      6002 => 'redis_cluster_dev_3',
      6003 => 'redis_cluster_test_1',
      6004 => 'redis_cluster_test_2',
      6005 => 'redis_cluster_test_3',
      6060 => 'gitlab-zoekt-indexer-test',
      6070 => 'zoekt-webserver-test',
      6080 => 'gitlab-zoekt-indexer-development',
      6090 => 'zoekt-webserver-development',
      6432 => 'pgbouncer_replica-1',
      6433 => 'pgbouncer_replica-2',
      6434 => 'pgbouncer_replica-2-1',
      6435 => 'pgbouncer_replica-2-2',
      8001 => 'gitlab_spamcheck',
      8065 => 'mattermost',
      8080 => 'nginx',
      8081 => 'gitlab_spamcheck_external', # was 8080
      8123 => 'clickhouse_http',
      8200 => 'vault',
      9000 => 'object_store',
      9001 => 'clickhouse_tcp',
      9002 => 'object_store_console',
      9009 => 'clickhouse_interserver',
      9090 => 'prometheus',
      9091 => 'snowplow_micro',
      9122 => 'gitlab_shell_exporter',
      9229 => 'workhorse_exporter',
      9236 => 'gitaly_exporter',
      10101 => 'praefect_exporter'
    }.freeze

    attr_reader :claimed_ports_and_services

    def initialize(config)
      @config = config
      @claimed_ports_and_services = {}
    end

    def claim(port, service_name)
      existing_service_name = claimed_service_for_port(port)

      if existing_service_name
        return true if existing_service_name == service_name

        raise PortAlreadyAllocated, "Port #{port} is already allocated for service '#{existing_service_name}'"
      end

      claimed_ports_and_services[port] = service_name

      true
    end

    def claimed_service_for_port(port)
      claimed_ports_and_services[port]
    end

    def default_port_for_service(name)
      port = DEFAULT_PORTS_FOR_SERVICES.invert[name]
      raise ServiceUnknownError, "Service '#{name}' is unknown, please add to GDK::PortManager::DEFAULT_PORTS_FOR_SERVICES" unless port

      port
    end

    private

    attr_reader :config
    attr_writer :claimed_ports_and_services
  end
end
