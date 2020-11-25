# frozen_string_literal: true

require_relative 'base'

module GDK
  module ConfigType
    class String < Base
      class Instance < Base::Instance
        def parse
          return false if value.nil?

          self.value = value.to_s

          true
        end
      end
    end
  end
end
