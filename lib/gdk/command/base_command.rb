# frozen_string_literal: true

module GDK
  module Command
    # Base interface for GDK commands
    class BaseCommand
      attr_reader :stdout, :stderr

      def initialize(stdout: GDK::Output, stderr: GDK::Output)
        @stdout = stdout
        @stderr = stderr
      end

      def run(args = [])
        raise NotImplementedError
      end

      protected

      def config
        @config ||= GDK.config
      end

      def display_help_message
        GDK.puts_separator <<~HELP_MESSAGE
          You can try the following that may be of assistance:

          - Run 'gdk doctor'.

          - Visit the troubleshooting documentation:
            https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/troubleshooting/index.md.
          - Visit https://gitlab.com/gitlab-org/gitlab-development-kit/-/issues to
            see if there are known issues.

          - Run 'gdk reset-data' if appropriate.
          - Run 'gdk pristine' which will restore your GDK to a pristine state.
        HELP_MESSAGE
      end

      def print_ready_message
        GDK::Output.puts

        if config.rails_web?
          debug_info = GDK::Command::DebugInfo.new
          GDK::Output.notice("GitLab available at #{config.__uri}.")
          GDK::Output.notice("  - Ruby: #{debug_info.ruby_version}.")
          GDK::Output.notice("  - Node.js: #{debug_info.node_version}.")
        end

        GDK::Output.notice("GitLab Docs available at http://#{config.hostname}:#{config.gitlab_docs.port}.") if config.gitlab_docs.enabled?

        if config.gitlab_k8s_agent?
          GDK::Output.notice("GitLab Agent Server (KAS) available at #{config.gitlab_k8s_agent.__url_for_agentk}.")
          GDK::Output.notice("Kubernetes proxy (via KAS) available at #{config.gitlab_k8s_agent.__k8s_api_url}.")
        end

        GDK::Output.notice("Prometheus available at http://#{config.hostname}:#{config.prometheus.port}.") if config.prometheus?
        GDK::Output.notice("Grafana available at http://#{config.hostname}:#{config.grafana.port}.") if config.grafana?
        GDK::Output.notice("A container registry is available at #{config.registry.host}:#{config.registry.port}.") if config.registry?
      end
    end
  end
end
