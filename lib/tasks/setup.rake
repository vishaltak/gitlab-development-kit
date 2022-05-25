# frozen_string_literal: true

desc 'Preflight checks for dependencies'
task 'preflight-checks' do
  checker = GDK::Dependencies::Checker.new
  checker.check_all

  unless checker.error_messages.empty?
    warn checker.error_messages
    exit 1
  end
end

desc 'Preflight Update checks'
task 'preflight-update-checks' do
  postgresql = GDK::Postgresql.new
  if postgresql.installed? && postgresql.upgrade_needed?
    message = <<~MESSAGE
      PostgreSQL data directory is version #{postgresql.current_version} and must be upgraded to version #{postgresql.class.target_version} before GDK can be updated.

      Run 'support/upgrade-postgresql' to back up and upgrade the PostgreSQL data directory.

    MESSAGE

    GDK::Output.abort(message)
  end
end

namespace :dependencies do
  desc 'Install services dependencies'
  task 'all' => [:clickhouse]

  desc 'Install ClickHouse'
  task :clickhouse do
    next unless GDK.config.clickhouse.enabled?
    next if GDK::Clickhouse.new.installed?

    installer = GDK::TaskHelpers::ClickhouseInstaller.new

    if GDK::Machine.linux? && GDK::Machine.x86_64?
      GDK::Output.notice('Downloading ClickHouse for Linux x86_64...')

      installer.fetch_linux64
    elsif GDK::Machine.macos? && GDK::Machine.arm64?
      GDK::Output.notice('Downloading ClickHouse for MacOS with Apple Silicon...')

      installer.fetch_macos_apple_silicon
    elsif GDK::Machine.macos? && GDK::Machine.x86_64?
      GDK::Output.notice('Downloading ClickHouse for MacOS with Intel processor...')

      installer.fetch_macos_intel
    else
      GDK::Output.warn("Can't automatically install ClickHouse in this operational system")
      GDK::Output.info('Learn how to install ClickHouse here: https://clickhouse.com/docs/en/quick-start')
    end
  end
end
