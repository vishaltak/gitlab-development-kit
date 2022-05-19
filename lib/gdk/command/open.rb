# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk reconfigure` command execution
    class Open < BaseCommand
      def run(args = [])
        unless args.delete('--help').nil?
          print_help
          return true
        end

        wait_until_ready = !args.delete('--wait-until-ready').nil?

        if wait_until_ready
          if test_url.check_url_oneshot
            open_exec
            return true
          end

          unless test_url.wait(verbose: false)
            GDK::Output.error('GDK is not up. Please run `gdk start` and try again.')
            return false
          end
        end

        open_exec
        true
      rescue Interrupt
        # CTRL-C was pressed
        true
      end

      private

      def print_help
        help = <<~HELP
          Usage: gdk open [<args>]

            --help              Display help
            --wait-until-ready  Wait until the GitLab web UI is ready before opening in your default web browser
        HELP

        GDK::Output.puts(help)

        true
      end

      def test_url
        @test_url ||= GDK::TestURL.new
      end

      def open_exec
        exec("#{open_command} '#{config.__uri}'")
      end

      def open_command
        @open_command ||= config.__platform_linux? ? 'xdg-open' : 'open'
      end
    end
  end
end
