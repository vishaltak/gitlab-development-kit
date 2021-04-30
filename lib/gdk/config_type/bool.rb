# frozen_string_literal: true

require_relative 'base'

module GDK
  module ConfigType
    class Bool < Base
      def self.cast_value(value)
        case value
        when 'true', true, 't', '1', 1
          true
        when 'false', false, 'f', '0', 0
          false
        else
          raise TypeError, "'#{value}' does not appear to be a valid Boolean."
        end
      end

      def parse
        self.value = self.class.cast_value(value)

        true
      rescue TypeError
        false
      end
    end
  end
end
