# frozen_string_literal: true

module GDK
  module Services
    class RailsWeb < Required
      def name
        'rails-web'
      end

      def command
        %(/usr/bin/env RAILS_ENV=development RAILS_RELATIVE_URL_ROOT=#{relative_url_root} support/exec-cd gitlab bin/web start_foreground)
      end

      private

      def relative_url_root
        config.relative_url_root
      end
    end
  end
end
