# frozen_string_literal: true

require_relative 'base'

module GDK
  module ConfigType
    class String < Base
      def parse(value)
        raise ::TypeError if value.nil?

        value.to_s
      end
    end
  end
end
