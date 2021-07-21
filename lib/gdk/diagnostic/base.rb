# frozen_string_literal: true

require 'stringio'

module GDK
  module Diagnostic
    class Base
      def diagnose
        raise NotImplementedError
      end

      def success?
        raise NotImplementedError
      end

      def message(content = detail)
        raise NotImplementedError unless title

        <<~MESSAGE

          #{title}
          #{'=' * 80}
          #{content}
        MESSAGE
      end

      def detail
        ''
      end

      def title
        self.class::TITLE
      end

      private

      def config
        @config ||= GDK::Config.new
      end
    end
  end
end
