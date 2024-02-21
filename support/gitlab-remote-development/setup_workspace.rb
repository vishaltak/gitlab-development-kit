#!/usr/bin/env ruby
#
# frozen_string_literal: true

require_relative '../../lib/gdk'

class SetupWorkspace
  ROOT_DIR = '/projects/gitlab-development-kit'
  GDK_SETUP_FLAG_FILE = "#{ROOT_DIR}/.cache/.gdk_setup_complete".freeze

  def run
    if bootstrap_needed?
      success, duration = execute_bootstrap

      create_flag_file if success

      return unless allow_sending_telemetry?

      send_telemetry(success, duration)
    else
      GDK::Output.info("#{GDK_SETUP_FLAG_FILE} exists, GDK has already been bootstrapped.\n\nRemove the #{GDK_SETUP_FLAG_FILE} to re-bootstrap.")
    end
  end

  private

  def bootstrap_needed?
    !File.exist?(GDK_SETUP_FLAG_FILE)
  end

  def execute_bootstrap
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    success = Shellout.new('support/gitlab-remote-development/remote-development-gdk-bootstrap.sh', chdir: ROOT_DIR).execute
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

    [success, duration]
  end

  def allow_sending_telemetry?
    GDK::Output.prompt('Would you like to send the duration data? [y/N]').match?(/\Ay(?:es)*\z/i)
  end

  def send_telemetry(success, duration)
    GDK.config.bury!('telemetry.username', 'remote')
    GDK.config.save_yaml!
    GDK::Telemetry.send_telemetry(success, 'setup-workspace', { duration: duration })
  end

  def create_flag_file
    FileUtils.mkdir_p(File.dirname(GDK_SETUP_FLAG_FILE))
    FileUtils.touch(GDK_SETUP_FLAG_FILE)
  end
end

SetupWorkspace.new.run if $PROGRAM_NAME == __FILE__
