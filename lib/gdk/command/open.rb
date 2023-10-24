# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk reconfigure` command execution
    class Open < BaseCommand
      def run(args = [])
        return true if print_help(args)
        return wait_until_ready if args.delete('--wait-until-ready')

        open_exec
      end

      def help
        <<~HELP
          Usage: gdk open [<args>]

            -h, --help          Display help
            --wait-until-ready  Wait until the GitLab web UI is ready before opening in your default web browser
        HELP
      end

      private

      def wait_until_ready
        return open_exec if test_url.check_url_oneshot

        unless test_url.wait(verbose: false)
          GDK::Output.error('GDK is not up. Please run `gdk start` and try again.')
          return false
        end

        open_exec
      rescue Interrupt
        # CTRL-C was pressed
        false
      end

      def test_url
        @test_url ||= GDK::TestURL.new
      end

      def open_exec
        exec("#{open_command} '#{config.__uri}'")
      end

      def open_command
        @open_command ||= if GDK::Machine.wsl?
                            'pwsh.exe -Command Start-Process'
                          elsif GDK::Machine.linux?
                            'xdg-open'
                          else
                            'open'
                          end
      end
    end
  end
end
