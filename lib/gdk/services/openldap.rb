# frozen_string_literal: true

module GDK
  module Services
    # OpenLDAP service
    class OpenLDAP < Base
      def name
        'openldap'
      end

      def command
        %(support/exec-cd gitlab-openldap libexec/slapd -F slapd.d -d2 -h "#{ldap_url}")
      end

      def enabled?
        config.openldap?
      end

      private

      def ldap_url
        "ldap://#{config.hostname}:3890"
      end
    end
  end
end
