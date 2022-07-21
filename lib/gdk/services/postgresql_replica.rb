# frozen_string_literal: true

module GDK
  module Services
    # PostgreSQL server replica
    class PostgreSQLReplica < Base
      def name
        'postgresql-replica'
      end

      def command
        %(support/postgresql-signal-wrapper #{postgresql_bin} -D #{postgresql_data_dir} -k #{postgresql_replica_dir} -h )
      end

      def enabled?
        config.postgresql.replica?
      end

      private

      def postgresql_bin
        config.postgresql.bin
      end

      def postgresql_replica_dir
        config.postgresql.replica_dir
      end

      def postgresql_data_dir
        postgresql_replica_dir.join('data')
      end

      def postgresql_active_host
        config.postgresql.__active_host
      end
    end
  end
end
