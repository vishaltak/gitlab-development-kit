# frozen_string_literal: true

module GDK
  module Services
    class RailsBackgroundJobs < Required
      def name
        'rails-background-jobs'
      end

      def command
        %(/usr/bin/env SIDEKIQ_LOG_ARGUMENTS=1 SIDEKIQ_WORKERS=1 RAILS_ENV=development RAILS_RELATIVE_URL_ROOT=#{relative_url_root} support/exec-cd gitlab bin/background_jobs start_foreground)
      end

      private

      def relative_url_root
        config.relative_url_root
      end
    end
  end
end
