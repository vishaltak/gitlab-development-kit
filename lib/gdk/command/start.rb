# frozen_string_literal: true

module GDK
  module Command
    # Start all enabled services or specified ones only
    class Start < BaseCommand
      def run(args = [])
        result = GDK::Hooks.with_hooks(GDK.config.gdk.start_hooks, 'gdk start') do
          Runit.sv('start', args)
        end

        # Only print if run like `gdk start`, not e.g. `gdk start rails-web`
        print_url_ready_message if args.empty?

        result
      end

      def print_url_ready_message
        GDK::Output.puts
        GDK::Output.notice("GitLab will be available at #{GDK.config.__uri} shortly.")
        GDK::Output.notice("GitLab Docs will be available at http://#{GDK.config.hostname}:#{GDK.config.gitlab_docs.port} shortly.") if GDK.config.gitlab_docs.enabled?
        GDK::Output.notice("GitLab Kubernetes Agent Server available at #{GDK.config.gitlab_k8s_agent.__url_for_agentk}.") if GDK.config.gitlab_k8s_agent?
      end
    end
  end
end
