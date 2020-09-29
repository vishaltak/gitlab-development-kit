# frozen_string_literal: true

module GDK
  class Postgresql
    def psql_cmd
      args = ARGV
      database = args.empty? ? default_database : nil

      pg_cmd(args, database: database).join(" ")
    end

    def ready?
      last_error = nil
      cmd = pg_cmd(database: 'template1')

      10.times do
        shellout = Shellout.new(cmd)
        shellout.run
        last_error = shellout.read_stderr

        return true if shellout.success?

        sleep 1
      end

      GDK::Output.error(last_error)
      false
    end

    def use_tcp?
      !config.host.start_with?('/')
    end

    def db_exists?(dbname)
      Shellout.new(pg_cmd(database: dbname)).tap(&:try_run).success?
    end

    def createdb(*args)
      cmd = pg_cmd(*args, program: 'createdb')

      Shellout.new(cmd).run
    end

    def in_recovery?
      cmd = pg_cmd('--no-psqlrc', '--tuples-only',
                   database: 'postgres',
                   command: 'SELECT pg_is_in_recovery();')

      Shellout.new(cmd).try_run.downcase.strip.chomp == 't'
    end

    private

    def config
      @config ||= GDK.config.postgresql
    end

    def host
      config.dir.to_s
    end

    def port
      config.port.to_s
    end

    def pg_cmd(*args, program: 'psql', database: nil, command: nil)
      cmd = [bin_dir.join(program).to_s]
      cmd << "--host=#{host}"
      cmd << "--port=#{port}"
      cmd << "--dbname=#{database}" if database
      cmd << "--command=#{command}" if command

      cmd + args
    end

    def default_database
      'gitlabhq_development'
    end

    def bin_dir
      config.bin_dir
    end
  end
end
