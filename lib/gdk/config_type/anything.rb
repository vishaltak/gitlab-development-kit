# frozen_string_literal: true

module GDK
  module ConfigType
    class Anything < Base
      def parse(value)
        value
      end
    end
  end
end
