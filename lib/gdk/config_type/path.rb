# frozen_string_literal: true

require_relative 'base'
require 'pathname'

module GDK
  module ConfigType
    class Path < Base
      def dump!(user_only: false)
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
