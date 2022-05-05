# frozen_string_literal: true

require 'socket'
require 'fileutils'

require_relative '../gdk'

module Support
  class BootstrapRails
    # The log file should be in the "support" folder, not in "suppport/lib"
    LOG_FILE            = '../bootstrap-rails.log'
    RAKE_DEV_SETUP_CMD  = %w[support/exec-cd gitlab bundle exec rake dev:setup].freeze
    RAKE_COPY_DB_CI_CMD = %w[support/exec-cd gitlab bundle exec rake dev:copy_db:ci].freeze

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
      run_rake_task_if_db_not_found('gitlabhq_development', RAKE_DEV_SETUP_CMD)
    end

    def bootstrap_ci_db
      return if !config.gitlab.rails.databases.ci.__enabled || config.gitlab.rails.databases.ci.__use_main_database

      run_rake_task_if_db_not_found('gitlabhq_development_ci', RAKE_COPY_DB_CI_CMD)
    end

    def run_rake_task_if_db_not_found(db, rake_task)
      if postgresql.db_exists?(db)
        GDK::Output.info("#{db} exists, nothing to do here.")
      else
        test_gitaly_up!

        result = Shellout.new(rake_task).execute(retry_attempts: 3)
        unless result.success?
          GDK::Output.abort <<~MESSAGE
            The command "#{rake_task.drop(2).join(' ')}" failed. Try to run it again with:

            #{rake_task.join(' ')}
          MESSAGE
        end
      end

      true
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
