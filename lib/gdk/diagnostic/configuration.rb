# frozen_string_literal: true

require 'stringio'

module GDK
  module Diagnostic
    class Configuration < Base
      TITLE = 'GDK Configuration'

      def diagnose
        output = GDK::OutputBuffered.new

        GDK::Command::DiffConfig.new(stdout: output, stderr: output).run

        @config_diff = output.dump.chomp
      end

      def success?
        @config_diff.empty?
      end

      def detail
        <<~MESSAGE
          Please review the following diff(s) and/or consider running `gdk reconfigure`:

          #{@config_diff}
        MESSAGE
      end
    end
  end
end
