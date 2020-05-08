# frozen_string_literal: true

module GDK
  module Services
    class OpenLDAP < Base
      def name
        'openldap'
      end

      def command
        %(support/exec-cd gitlab-openldap libexec/slapd -F slapd.d -d2 -h "ldap://#{config.hostname}:3890")
      end

      def enabled?
        settings.enabled?
      end

      private

      def settings
        @settings ||= config.openldap
      end
    end
  end
end
