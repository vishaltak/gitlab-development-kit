# frozen_string_literal: true

module GDK
  module Services
    class Vault < Base
      def name
        'vault'
      end

      def command
        config.vault.__server_command
      end

      def enabled?
        config.vault.enabled?
      end
    end
  end
end
