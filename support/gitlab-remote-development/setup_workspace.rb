#!/usr/bin/env ruby
#
# frozen_string_literal: true

require_relative '../../lib/gdk'

class SetupWorkspace
  ROOT_DIR = '/projects/gitlab-development-kit'
  GDK_BOOTSTRAPPED_FILE = "#{ROOT_DIR}/.cache/.gdk_bootstrapped".freeze

  def run
    if bootstrap_needed?
      success, duration = execute_bootstrap

      return unless allow_sending_telemetry?

      send_telemetry(success, duration)
    else
      GDK::Output.info("#{GDK_BOOTSTRAPPED_FILE} exists, GDK has already been bootstrapped.\n\nRemove the #{GDK_BOOTSTRAPPED_FILE} to re-bootstrap.")
    end
  end

  private

  def bootstrap_needed?
    !File.exist?(GDK_BOOTSTRAPPED_FILE)
  end

  def execute_bootstrap
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    success = Dir.chdir(ROOT_DIR) do
      system('support/gitlab-remote-development/remote-development-gdk-bootstrap.sh')
    end
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

    [success, duration]
  end

  def allow_sending_telemetry?
    GDK::Output.print('Would you like to send the duration data? (yes/no): ')
    $stdin.gets&.chomp == 'yes'
  end

  def send_telemetry(success, duration)
    GDK.config.bury!('telemetry.username', 'remote')
    GDK.config.save_yaml!
    GDK::Telemetry.send_telemetry(success, 'setup-workspace', { duration: duration })
  end
end

SetupWorkspace.new.run if $PROGRAM_NAME == __FILE__
