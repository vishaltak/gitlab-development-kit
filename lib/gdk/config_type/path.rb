# frozen_string_literal: true

require_relative 'base'
require 'pathname'

module GDK
  module ConfigType
    class Path < Base
      class Instance < Base::Instance
        def dump!
          value.to_s
        end

        def parse
          self.value = Pathname.new(value)

          true
        rescue ::TypeError
          false
        end
      end
    end
  end
end
