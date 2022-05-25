# frozen_string_literal: true

module GDK
  module Command
    # Stop and restart all enabled services or specified ones only
    class Restart < BaseCommand
      def run(args = [])
        unless args.delete('--help').nil?
          Start.print_help
          return true
        end

        # Stop does not support --<arg> being passed in, so we need to strip
        # them here.
        GDK::Command::Stop.new.run(args.reject { |x| x.start_with?('--') })

        # Give services a little longer to shutdown.
        sleep(3)

        GDK::Command::Start.new.run(args)
      end
    end
  end
end
