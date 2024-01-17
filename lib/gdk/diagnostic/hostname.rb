# frozen_string_literal: true

require 'resolv'

module GDK
  module Diagnostic
    class Hostname < Base
      TITLE = 'GDK Hostname'

      def success?
        hostname_ips.include?(listen_address)
      end

      def detail
        return if success?

        if hostname_ips.empty?
          return <<~MESSAGE
            Could not resolve IP address for the GDK hostname `#{hostname}`
            Is it set up in `/etc/hosts`?
          MESSAGE
        end

        <<~MESSAGE
          The GDK hostname `#{hostname}` resolves to the IP addresses #{hostname_ips.join(', ')}.
          The listen_address defined in your GDK config is `#{listen_address}`.
          You should make sure that the two match.

          Either fix the IP address in `/etc/hosts` to match #{listen_address}, or run:

             #{hostname_ips.map { |ip| "gdk config set listen_address #{ip}" }.join("\n")}
        MESSAGE
      end

      private

      def hostname_ips
        @hostname_ip ||= Resolv.getaddresses(hostname)
      end

      def hostname
        @hostname ||= config.hostname
      end

      def listen_address
        @listen_address ||= config.listen_address
      end
    end
  end
end
