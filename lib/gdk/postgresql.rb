# frozen_string_literal: true

require 'fileutils'

module GDK
  autoload :LineInFile, 'gdk/line_in_file'
  autoload :PostgresqlGeoPrimary, 'gdk/postgresql_geo_primary'

  class Postgresql
    def psql_cmd(args)
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

    def initdb
      cmd = %W[#{bin_dir.join('initdb')} --locale=C --encoding=utf-8 #{config.data_dir}]
      Shellout.new(cmd).run!
    end

    def createdb(*args)
      cmd = pg_cmd(*args, program: 'createdb')

      Shellout.new(cmd).run
    end

    def in_recovery?
      query(<<~SQL).casecmp('t').zero?
        SELECT pg_is_in_recovery();
      SQL
    end

    def trust_replication
      pg_hba = LineInFile.new(config.data_dir.join('pg_hba.conf'))

      pg_hba.append(regexp: /gitlab_replication/) do
        'local   replication     gitlab_replication                      trust'
      end
    end

    def standby_mode
      return if version < 12

      # https://www.postgresql.org/docs/12/runtime-config-wal.html#RUNTIME-CONFIG-WAL-ARCHIVE-RECOVERY
      FileUtils.touch(config.data_dir.join('standby.signal'))
    end

    def query(sql, database: 'postgres')
      cmd = pg_cmd('--no-psqlrc', '--tuples-only',
                   database: database,
                   command: sql.strip)

      Shellout.new(cmd).try_run.strip
    end

    def reconfigure
      postgresql_conf = LineInFile.new(config.data_dir.join('postgresql.conf'))

      # Remove old style includes
      postgresql_conf.remove(regexp: /include 'gitlab.conf'/)
      postgresql_conf.remove(regexp: /include 'replication.conf'/)
      FileUtils.rm_f([config.data_dir.join('gitlab.conf'),
                      config.data_dir.join('replication.conf')])

      postgresql_conf.append(line: "include 'gdk.conf'\n")

      erb_render('gdk.conf')
      erb_render('recovery.conf') if config.root.geo.secondary? && version < 12
    end

    def version
      @version ||=
        Shellout.new(bin_dir.join('psql').to_s, '--version').try_run
                .match(/psql.* (\d+)\.\d+/).captures.first.to_i
    end

    def config
      @config ||= GDK.config.postgresql
    end

    def primary_config
      @primary_config ||=
        begin
          GDK::PostgresqlGeoPrimary.new.config
        rescue PostgresqlGeoPrimary::PathNotSpecified
          nil
        end
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

    def erb_render(file)
      template = "support/templates/postgresql.#{file}.erb"
      erb_args = {
        config: config,
        primary_config: primary_config,
        pg_version: version
      }

      ErbRenderer.new(template, config.data_dir.join(file), erb_args).render!
    end
  end
end
