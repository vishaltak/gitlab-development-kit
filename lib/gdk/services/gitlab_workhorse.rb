# frozen_string_literal: true

module GDK
  module Services
    # GitLab Workhorse service
    class GitLabWorkhorse < Required
      def name
        'gitlab-workhorse'
      end

      def command
        command = %W[/usr/bin/env PATH="#{workhorse_dir}:$PATH"]
        command << 'GEO_SECONDARY_PROXY=0' unless config.geo?
        command += %W[gitlab-workhorse -#{auth_type_flag} "#{auth_address}"]
        command += %W[-documentRoot "#{document_root}"]
        command += %W[-developmentMode -secretPath "#{secret_path}"]
        command += %W[-config "#{config_file}"]
        command += %W[-listenAddr "#{listen_address}"]
        command += %w[-logFormat json]
        command += %W[-prometheusListenAddr "#{prometheus_listen_addr}"] if config.prometheus.enabled?

        command.join(' ')
      end

      private

      def workhorse_dir
        config.gitlab.dir.join('workhorse')
      end

      def auth_type_flag
        config.workhorse.__listen_settings.__type
      end

      def auth_address
        config.workhorse.__listen_settings.__address
      end

      def document_root
        config.gitlab.dir.join('public').to_s
      end

      def secret_path
        config.gitlab.dir.join('.gitlab_workhorse_secret').to_s
      end

      def config_file
        workhorse_dir.join('config.toml')
      end

      def listen_address
        config.workhorse.__command_line_listen_addr
      end

      def prometheus_listen_addr
        "#{config.hostname}:#{config.prometheus.workhorse_exporter_port}"
      end
    end
  end
end
