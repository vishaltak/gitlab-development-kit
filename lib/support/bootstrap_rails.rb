# frozen_string_literal: true

require 'socket'
require 'fileutils'

require_relative '../gdk'

module Support
  # Bootstrap GitLab rails environment
  class BootstrapRails
    # The log file should be in the "support" folder, not in "suppport/lib"
    LOG_FILE = '../bootstrap-rails.log'

    def execute
      if config.geo.secondary?
        GDK::Output.info("Exiting as we're a Geo secondary.")
        exit
      end

      GDK::Output.abort('Cannot connect to PostgreSQL.') unless postgresql.ready?
      FileUtils.rm_f(LOG_FILE)

      bootstrap_main_db && bootstrap_ci_db && bootstrap_embedding_db
    end

    private

    def bootstrap_main_db
      if_db_not_found('gitlabhq_development') do
        run_tasks('db:reset') &&
          set_feature_flags &&
          seed_main_db
      end
    end

    def set_feature_flags
      # Nothing set right now
      true
    end

    def cells_secondary?
      config.cells.postgresql_clusterwide.host != config.postgresql.host ||
        config.cells.postgresql_clusterwide.port != config.postgresql.port
    end

    # TODO: Skip seeding due to https://gitlab.com/gitlab-org/gitlab/-/issues/412075
    def seed_main_db
      return if cells_secondary?

      run_tasks('db:seed_fu')
    end

    def bootstrap_ci_db
      return if !config.gitlab.rails.databases.ci.__enabled || config.gitlab.rails.databases.ci.__use_main_database

      if_db_not_found('gitlabhq_development_ci') do
        run_tasks('dev:copy_db:ci')
      end
    end

    def bootstrap_embedding_db
      return unless config.gitlab.rails.databases.embedding.enabled

      if_db_not_found('gitlabhq_development_embedding') do
        run_tasks('db:reset:embedding')
      end
    end

    def run_tasks(*tasks)
      test_gitaly_up!

      rake = GDK::Execute::Rake.new(*tasks)
      unless rake.execute_in_gitlab(retry_attempts: 3).success?
        GDK::Output.abort <<~MESSAGE
          The rake task '#{tasks.join(' ')}' failed. Trying to run it again!
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
      system('grep', "#{service}.1", LOG_FILE)

      abort
    end
  end
end
