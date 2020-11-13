# frozen_string_literal: true

module GDK
  module Diagnostic
    class RubyGems < Base
      TITLE = 'Ruby Gems'
      GEMS_TO_CHECK = %w[charlock_holmes eventmachine ffi pg].freeze

      def diagnose
        # no-op
      end

      def success?
        failed_to_load_gems.empty?
      end

      def detail
        return error_message unless failed_to_load_gems.empty?
      end

      private

      def failed_to_load_gems
        @failed_to_load_gems ||= begin
          GEMS_TO_CHECK.reject do |name|
            gem_ok?(name)
          end
        end
      end

      def gem_ok?(name)
        require name
        true
      rescue LoadError => e
        GDK::Output.error(format('%<error>s - %<trace>s', error: e, trace: e.backtrace.join("\n")))
        GDK::Output.puts
        false
      end

      def error_message
        <<~MESSAGE
          The following Ruby Gems have issues:

          #{@failed_to_load_gems.join("\n")}

          Try running the following to fix:

          gem pristine #{@failed_to_load_gems.join(' ')}
        MESSAGE
      end
    end
  end
end
