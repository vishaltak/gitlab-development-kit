# frozen_string_literal: true

require_relative 'base'
require 'pathname'

module GDK
  module ConfigType
    class Path < Base
      def dump!(user_only: false)
        value.to_s
      end

      def parse(value)
        Pathname.new(value)
      end

      private

      def string_like?
        %w[String Pathname].include?(value.class.to_s)
      end
    end
  end
end
