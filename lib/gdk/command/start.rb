# frozen_string_literal: true

module GDK
  module Command
    # Start all enabled services or specified ones only
    class Start < BaseCommand
      def run(args = [])
        unless args.delete('--help').nil?
          print_help
          return true
        end

        show_progress = !args.delete('--show-progress').nil?
        open_when_ready = !args.delete('--open-when-ready').nil?

        result = GDK::Hooks.with_hooks(config.gdk.start_hooks, 'gdk start') do
          Runit.start(args)
        end

        if args.empty?
          # Only print if run like `gdk start`, not e.g. `gdk start rails-web`
          print_url_ready_message

          # Only test URL if --show-progress specified
          if show_progress
            GDK::Output.puts
            test_url
          end

          # Only open URL if --open-when-ready specified
          if open_when_ready
            GDK::Output.puts
            open_in_web_browser
          end
        end

        result
      end

      private

      def print_help
        help = <<~HELP
          Usage: gdk start [<args>]

            --help             Display help
            --show-progress    Indicate when GDK is ready to use
            --open-when-ready  Open the GitLab web UI running in your local GDK installation, using your default web browser
        HELP

        GDK::Output.puts(help)
      end

      def test_url
        GDK::TestURL.new.wait
      end

      def open_in_web_browser
        GDK::Command::Open.new.run
      end
    end
  end
end
