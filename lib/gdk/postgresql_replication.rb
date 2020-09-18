# frozen_string_literal: true

module GDK
  class PostgresqlReplication
    attr_accessor :primary_postgresql

    def initialize(primary:)
      @primary_postgresql = primary
    end

    def setup
      postgresql.initdb
      postgresql.trust_replication

      primary_postgresql.query(<<~SQL)
        SELECT pg_start_backup('base backup for streaming rep')
      SQL

      rsync_from_primary

      primary_postgresql.query(<<~SQL)
        SELECT pg_stop_backup(), current_timestamp
      SQL

      postgresql.standby_mode
    end

    private

    def rsync_from_primary
      cmd = %W[rsync -cva --inplace --exclude=*pg_xlog* --exclude=*.pid #{primary_postgresql.config.data_dir} #{postgresql.config.dir}]
      sh = Shellout.new(cmd)
      sh.stream!
    end

    def postgresql
      @postgresql ||= Postgresql.new
    end
  end
end
