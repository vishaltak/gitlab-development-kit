# frozen_string_literal: true

module GDK
  module Services
    # Toxiproxy service for network simulation
    # https://github.com/Shopify/toxiproxy
    class Toxiproxy < Base
      def name
        'toxiproxy'
      end

      def command
        %(env toxiproxy-server -host #{config.listen_address} -port #{config.toxiproxy.port})
      end

      def enabled?
        config.toxiproxy.enabled?
      end
    end
  end
end
