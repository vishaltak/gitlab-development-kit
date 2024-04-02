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

      def help
        raise NotImplementedError
      end

      protected

      def config
        @config ||= GDK.config
      end

      def print_help(args)
        return false unless (args & ['-h', '--help']).any?

        GDK::Output.puts(help)

        true
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
        notices = []

        if config.rails_web?
          debug_info = GDK::Command::DebugInfo.new
          notices << "GitLab available at #{config.__uri}."
          notices << "  - Ruby: #{debug_info.ruby_version}."
          notices << "  - Node.js: #{debug_info.node_version}."
        end

        notices << "GitLab Docs available at #{config.gitlab_docs.__uri}." if config.gitlab_docs?

        if config.gitlab_k8s_agent?
          notices << "GitLab Agent Server (KAS) available at #{config.gitlab_k8s_agent.__url_for_agentk}."
          notices << "Kubernetes proxy (via KAS) available at #{config.gitlab_k8s_agent.__k8s_api_url}."
        end

        notices << "GitLab AI Gateway is available at #{config.gitlab_ai_gateway.__listen}." if config.gitlab_ai_gateway?

        notices << "Prometheus available at #{config.prometheus.__uri}." if config.prometheus?
        notices << "Grafana available at #{config.grafana.__uri}." if config.grafana?
        notices << "A container registry is available at #{config.registry.__listen}." if config.registry?

        return if notices.empty?

        GDK::Output.puts
        notices.each { |msg| GDK::Output.notice(msg) }
      end
    end
  end
end
