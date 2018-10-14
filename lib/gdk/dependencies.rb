# frozen_string_literals: true
require 'English'

module Gdk
  class Dependencies
    def self.mysql_present?
      `mysql_config --libs 2>/dev/null`

      # if above command exits with 0 means mysql is available
      $CHILD_STATUS.exitstatus.zero?
    end

    def self.command_present?(command)
      `command -v #{command}`

      # if above command exits with 0 means command is available
      $CHILD_STATUS.exitstatus.zero?
    end
  end
end