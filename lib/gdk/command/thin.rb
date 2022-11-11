# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk thin` command execution
    class Thin < BaseCommand
      def run(args = [])
        GDK::Output.puts 'This command is deprecated. Use the following command instead:'
        GDK::Output.puts
        GDK::Output.puts '    gdk stop rails-web && GITLAB_RAILS_RACK_TIMEOUT_ENABLE_LOGGING=false PUMA_SINGLE_MODE=true gdk rails s'

        false
      end
    end
  end
end
