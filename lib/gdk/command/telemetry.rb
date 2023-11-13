# frozen_string_literal: true

module GDK
  module Command
    class Telemetry < BaseCommand
      def run(_ = [])
        puts <<~TEXT
          To improve GDK, GitLab would like to collect basic error and usage data. Please choose one of the following options:

          - To send data to GitLab, enter your GitLab username.
          - To send data to GitLab anonymously, leave blank.
          - To avoid sending data to GitLab, enter a period ('.').
        TEXT

        username = $stdin.gets&.chomp
        ::Telemetry.update_settings(username)

        puts \
          case username
          when '.'
            'Error tracking and analytic data will not be collected.'
          when '', NilClass
            'Error tracking and analytic data will now be collected anonymously.'
          else
            "Error tracking and analytic data will now be collected as '#{username}'."
          end

        true
      end
    end
  end
end
