# frozen_string_literal: true

module GDK
  module Diagnostic
    class Asdf < Base
      TITLE = 'asdf'

      def diagnose
        nil
      end

      def success?
        no_unnecessary_software_to_uninstall?
      end

      def detail
        return if success?

        output = []
        output << display_unncessary_software_to_uninstall unless no_unnecessary_software_to_uninstall?
        output.compact.join("\n")
      end

      private

      def asdf_tool_versions
        @asdf_tool_versions ||= ::Asdf::ToolVersions.new
      end

      def no_unnecessary_software_to_uninstall?
        @no_unnecessary_software_to_uninstall ||= !asdf_tool_versions.unnecessary_software_to_uninstall?
      end

      def display_unncessary_software_to_uninstall
        output = ["The following asdf software is installed, but doesn't need to be:\n"]

        asdf_tool_versions.unnecessary_installed_versions_of_software.each do |name, versions|
          output << "#{name} #{versions.keys.join(', ')}"
        end

        output << ["\nYou can uninstall the software above by running:\n\n  rake asdf:uninstall_unnecessary_software"]
        output
      end
    end
  end
end
