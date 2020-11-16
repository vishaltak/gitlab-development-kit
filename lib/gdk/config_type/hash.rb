# frozen_string_literal: true

require 'json'
require_relative 'base'

module GDK
  module ConfigType
    class Hash < Base
      def parse
        value.is_a?(::Hash)
      end
    end
  end
end
