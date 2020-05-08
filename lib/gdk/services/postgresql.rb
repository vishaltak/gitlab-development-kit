# frozen_string_literal: true

module GDK
  module Services
    class PostgreSQL < Required
      def name
        'postgresql'
      end

      def command
        %(support/postgresql-signal-wrapper #{settings.bin} -D #{settings.data_dir} -k #{settings.dir} -h '')
      end

      private

      def settings
        @settings ||= config.postgresql
      end
    end
  end
end
