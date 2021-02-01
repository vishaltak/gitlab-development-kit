# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk install` command execution
    #
    # This command accepts the following parameters:
    # - gitlab_repo=<url to repository> (defaults to: "https://gitlab.com/gitlab-org/gitlab")
    class Install
      def run(args)
        result = GDK.make('install', *args)

        unless result
          GDK::Output.error('Failed to install.')
          GDK.display_help_message
        end

        result
      end
    end
  end
end
