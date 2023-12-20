# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk install` command execution
    #
    # This command accepts the following parameters:
    # - gitlab_repo=<url to repository> (defaults to: "https://gitlab.com/gitlab-org/gitlab")
    class Install < BaseCommand
      def run(args = [])
        args.each do |arg|
          next unless arg.start_with?('telemetry_user=')

          username = arg.split('=').last
          GDK::Telemetry.update_settings(username)

          break
        end

        result = GDK.make('install', *args)

        unless result.success?
          GDK::Output.error('Failed to install.', result.stderr_str)
          display_help_message
        end

        result.success?
      end
    end
  end
end
