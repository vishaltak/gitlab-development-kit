# frozen_string_literal: true

require_relative 'base'

module GDK
  module ConfigType
    class Integer < Base
      def parse(value)
        ival = value.to_i

        raise ::TypeError unless value.to_s == ival.to_s

        ival
      end
    end
  end
end
