# frozen_string_literal: true

module GDK
  module Diagnostic
    class Environment < Base
      TITLE = 'Environment variables'

      def success?
        ENV['RUBY_CONFIGURE_OPTS'].blank?
      end

      def detail
        return if success?

        <<~MESSAGE
          RUBY_CONFIGURE_OPTS is configured in your environment:

          RUBY_CONFIGURE_OPTS=#{ENV.fetch('RUBY_CONFIGURE_OPTS')}

          This should not be necessary and could interfere with your
          ability to build Ruby.

          Check your dotfiles (such as ~/.zshrc) and remove any lines that set
          this variable.
        MESSAGE
      end

      private

      def checker
        @checker ||= GDK::Dependencies::Checker.new.tap(&:check_all)
      end
    end
  end
end
