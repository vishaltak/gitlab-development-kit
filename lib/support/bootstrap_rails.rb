# frozen_string_literal: true

require 'socket'
require 'fileutils'

require_relative '../gdk'

module Support
  class BootstrapRails
    # The log file should be in the "support" folder, not in "suppport/lib"
    LOG_FILE = '../bootstrap-rails.log'
    RAKE_DEV_DB_RESET_CMD = %w[support/exec-cd gitlab ../support/bundle-exec rake db:reset].freeze
    RAKE_DEV_DB_SEED_CMD = %w[support/exec-cd gitlab ../support/bundle-exec rake db:seed_fu].freeze
    RAKE_COPY_DB_CI_CMD = %w[support/exec-cd gitlab ../support/bundle-exec rake dev:copy_db:ci].freeze

    def execute
      if config.geo.secondary?
        GDK::Output.info("Exiting as we're a Geo secondary.")
        exit
      end

      GDK::Output.abort('Cannot connect to PostgreSQL.') unless postgresql.ready?
      FileUtils.rm_f(LOG_FILE)

      bootstrap_main_db && bootstrap_ci_db
    end

    private

    def bootstrap_main_db
      if_db_not_found('gitlabhq_development') do
        run_command(RAKE_DEV_DB_RESET_CMD) && set_feature_flags && seed_main_db
      end
    end

    def set_feature_flags
      # Nothing set right now
      true
    end

    def seed_main_db
      run_command(RAKE_DEV_DB_SEED_CMD)
    end

    def bootstrap_ci_db
      return if !config.gitlab.rails.databases.ci.__enabled || config.gitlab.rails.databases.ci.__use_main_database

      if_db_not_found('gitlabhq_development_ci') do
        run_command(RAKE_COPY_DB_CI_CMD)
      end
    end

    def run_command(cmd)
      test_gitaly_up!

      result = Shellout.new(cmd).execute(retry_attempts: 3)
      unless result.success?
        GDK::Output.abort <<~MESSAGE
          The command '#{cmd.join(' ')}' failed. Try to run it again with:

          #{cmd.join(' ')}
        MESSAGE
      end

      true
    end

    def if_db_not_found(db)
      if postgresql.db_exists?(db)
        GDK::Output.info("#{db} exists, nothing to do here.")
        true
      else
        yield
      end
    end

    def postgresql
      @postgresql ||= GDK::Postgresql.new
    end

    def config
      @config ||= GDK::Config.new
    end

    def test_gitaly_up!
      try_connect!(config.praefect? ? 'praefect' : 'gitaly')
    end

    def try_connect!(service)
      print "Waiting for #{service} to boot"

      sleep_time = 0.1
      repeats = 100

      repeats.times do
        sleep sleep_time
        print '.'

        begin
          UNIXSocket.new("#{service}.socket").close
          GDK::Output.puts 'OK'

          return
        rescue Errno::ENOENT, Errno::ECONNREFUSED
        end
      end

      GDK::Output.error " failed to connect to #{service} after #{repeats * sleep_time}s"
      GDK::Output.puts(stderr: true)
      system('grep', "#{service}\.1", LOG_FILE)

      abort
    end
  end
end
