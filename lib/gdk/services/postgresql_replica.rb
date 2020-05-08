# frozen_string_literal: true

module GDK
  module Services
    class PostgreSQLReplica < Base
      def name
        'postgresql-replica'
      end

      def command
        %(support/postgresql-signal-wrapper #{settings.bin} -D #{settings.replica_dir.join('data')} -k #{settings.replica_dir} -h '')
      end

      def enabled?
        settings.replica.enabled?
      end

      private

      def settings
        @settings ||= config.postgresql
      end
    end
  end
end
