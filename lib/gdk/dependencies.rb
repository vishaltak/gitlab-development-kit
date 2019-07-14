# frozen_string_literals: true
require 'English'

module GDK
  class Dependencies
    VERSION_REGEXP = /[0-9]+\.[0-9]+\.[0-9]+/.freeze

    def self.command_present?(command)
      `command -v #{command}`

      # if above command exits with 0 means command is available
      $CHILD_STATUS.exitstatus.zero?
    end

    def self.ruby_bundler_version
      version_string = `bundle --versions`
      version_string.match(VERSION_REGEXP).to_s
    end
  end
end
