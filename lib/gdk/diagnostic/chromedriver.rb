# frozen_string_literal: true

module GDK
  module Diagnostic
    class Chromedriver < Base
      TITLE = 'Chromedriver'

      def success?
        !chrome_driver_installed
      end

      def detail
        return if success?

        <<~CHROME_DRIVER_INSTALLED
          You have chromedriver installed via homebrew.
          The gitlab project utilizes selenium-manager to manage Google Chrome
          and chromedriver versions. You may uninstall it with:

            brew uninstall chromedriver
        CHROME_DRIVER_INSTALLED
      end

      private

      def chrome_driver_installed
        return false unless ::GDK::Dependencies.homebrew_available?

        @chrome_driver_installed ||= begin
          sh = ::Shellout.new(%w[brew list chromedriver], chdir: config.gdk_root)
          sh.run
          sh.success?
        end
      end
    end
  end
end
