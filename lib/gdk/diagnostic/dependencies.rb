# frozen_string_literal: true

module GDK
  module Diagnostic
    class Dependencies < Base
      TITLE = 'GDK Dependencies'

      def success?
        checker.error_messages.empty?
      end

      def detail
        return if success?

        messages = checker.error_messages.join("\n").chomp

        <<~MESSAGE
          #{messages}

          For details on how to install, please visit:

          https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/index.md
        MESSAGE
      end

      private

      def checker
        @checker ||= GDK::Dependencies::Checker.new.tap(&:check_all)
      end
    end
  end
end
