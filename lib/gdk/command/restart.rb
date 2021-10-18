# frozen_string_literal: true

module GDK
  module Command
    # Stop and restart all enabled services or specified ones only
    class Restart < BaseCommand
      def run(args = [])
        GDK::Command::Stop.new.run(args)
        # Give services a little longer to shutdown.
        sleep(3)
        GDK::Command::Start.new.run(args)
      end
    end
  end
end
