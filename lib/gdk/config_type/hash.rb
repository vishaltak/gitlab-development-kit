# frozen_string_literal: true

require 'json'

module GDK
  module ConfigType
    class Hash < Base
      include Mergable

      def parse(value)
        if value.is_a?(::String)
          begin
            return JSON.parse(value)
          rescue JSON::ParserError => e
            raise StandardErrorWithMessage, e.message
          end
        end

        value.to_h
      end

      private

      def mergable_merge(fetched, default)
        Hash(fetched).merge(default.transform_keys(&:to_s))
      end
    end
  end
end
