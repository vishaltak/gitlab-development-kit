# frozen_string_literal: true

require 'sentry-ruby'

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

      def display_help_message(message)
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

        init_sentry
        if message.is_a?(Exception)
          exception = message
        else
          exception = StandardError.new(message)
          exception.set_backtrace(caller)
        end
        Sentry.capture_exception(exception)
        puts "/// Sentry.capture_exception(exception)"
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

        notices << "Prometheus available at #{config.prometheus.__uri}." if config.prometheus?
        notices << "Grafana available at #{config.grafana.__uri}." if config.grafana?
        notices << "A container registry is available at #{config.registry.__listen}." if config.registry?

        return if notices.empty?

        GDK::Output.puts
        notices.each { |msg| GDK::Output.notice(msg) }
      end

      def init_sentry
        Sentry.init do |config|
          config.dsn = 'https://glet_1a56990d202783685f3708b129fde6c0@observe.gitlab.com:443/errortracking/api/v1/projects/48924931'
          config.breadcrumbs_logger = [:sentry_logger]
          config.traces_sample_rate = 1.0
        end
      end
    end
  end
end
