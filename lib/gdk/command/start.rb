# frozen_string_literal: true

module GDK
  module Command
    # Start all enabled services or specified ones only
    class Start < BaseCommand
      def help
        <<~HELP
          Usage: gdk start [<args>]

            -h, --help         Display help
            --quiet            Don't display any output
            --show-progress    Indicate when GDK is ready to use
              or
            --open-when-ready  Open the GitLab web UI running in your local GDK installation, using your default web browser
        HELP
      end

      def run(args = [])
        return true if print_help(args)

        quiet = !args.delete('--quiet').nil?
        show_progress = !args.delete('--show-progress').nil?
        open_when_ready = !args.delete('--open-when-ready').nil?

        result = GDK::Hooks.with_hooks(config.gdk.start_hooks, 'gdk start') do
          Runit.start(args, quiet:)
        end

        if args.empty?
          # Only print if run like `gdk start`, not like `gdk start rails-web`
          print_ready_message
        end

        if show_progress
          GDK::Output.puts
          test_url
        elsif open_when_ready
          GDK::Output.puts
          open_in_web_browser
        end

        result
      end

      private

      def test_url
        GDK::TestURL.new.wait
      end

      def open_in_web_browser
        GDK::Command::Open.new.run(%w[--wait-until-ready])
      end
    end
  end
end
