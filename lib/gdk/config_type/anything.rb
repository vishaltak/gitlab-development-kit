# frozen_string_literal: true

require_relative 'base'

module GDK
  module ConfigType
    class Anything < Base
      def parse(value)
        value
      end
    end
  end
end
