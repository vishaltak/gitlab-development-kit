# frozen_string_literal: true

module GDK
  module Diagnostic
    class PGUser < Base
      TITLE = 'PGUSER environment variable'

      def diagnose
        nil
      end

      def success?
        !pguser_set?
      end

      def detail
        return pguser_set_message unless success?
      end

      private

      def pguser_set?
        ENV.has_key? 'PGUSER'
      end

      def pguser_set_message
        <<~MESSAGE
          The PGUSER environment variable is set and may cause issues with
          underlying postgresql commands ran by GDK.
        MESSAGE
      end
    end
  end
end
