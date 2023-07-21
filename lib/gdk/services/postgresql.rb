# frozen_string_literal: true

module GDK
  module Services
    # PostgreSQL server
    class PostgreSQL < Required
      def name
        'postgresql'
      end

      def command
        %(support/postgresql-signal-wrapper #{postgresql_bin} -D #{postgresql_data_dir} -k #{postgresql_dir} -h '#{postgresql_active_host}' -c max_connections=#{postgresql_max_connections})
      end

      private

      def postgresql_bin
        config.postgresql.bin
      end

      def postgresql_dir
        config.postgresql.dir
      end

      def postgresql_data_dir
        config.postgresql.data_dir
      end

      def postgresql_active_host
        config.postgresql.__active_host
      end

      def postgresql_max_connections
        config.postgresql.max_connections
      end
    end
  end
end
