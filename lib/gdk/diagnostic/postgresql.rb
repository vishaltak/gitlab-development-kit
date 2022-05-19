# frozen_string_literal: true

module GDK
  module Diagnostic
    class PostgreSQL < Base
      TITLE = 'PostgreSQL'

      # Check if the version of PostgreSQL in the PATH matches the
      # version in the data directory.
      def diagnose
        psql_command.try_run
        data_dir_version

        nil
      end

      def success?
        versions_ok? && can_create_postgres_socket?
      end

      def detail
        return if success?

        output = []
        output << version_problem_message unless versions_ok?
        output << cant_create_socket_message unless can_create_postgres_socket?

        output.join("\n#{diagnostic_detail_break}\n")
      end

      private

      def version_problem_message
        cmd_version = psql_version || 'unknown'
        data_version = data_dir_version || 'unknown'

        <<~MESSAGE
          `psql` is version #{cmd_version}, but your PostgreSQL data dir is using version #{data_version}.

          Check that your PATH is pointing to the right PostgreSQL version, or see the PostgreSQL upgrade guide:
          https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/postgresql.md#upgrade-postgresql
        MESSAGE
      end

      def can_create_postgres_socket?
        return true if Postgresql.new.use_tcp?

        # use a temporary file the same character length as 'postgresql/.s.PGSQL.port'
        # port max is 65535, so assume 5 characters for the port number
        # socket_path = config.gdk_root.join('postgresql_.s.PGSQL.XXXXX')
        socket_path = config.gdk_root.join('postgresql_.s.PGSQL.XXXXX').to_s

        can_create_socket?(socket_path)
      end

      def cant_create_socket_message
        <<~MESSAGE
          GDK directory's character length (#{config.gdk_root.to_s.length}) is too long to support the creation
          of a UNIX socket for Postgres:

            #{config.gdk_root}

          Try using a shorter directory path for GDK or use TCP for Postgres.
        MESSAGE
      end

      def versions_ok?
        psql_command.success? && psql_version && data_dir_version && versions_match?
      end

      def versions_match?
        if psql_version >= 10
          data_dir_version.to_i == psql_version.to_i
        else
          # Avoid floating point comparison issues by using rationals
          data_dir_version.to_r.round(2) == psql_version.to_r.round(2)
        end
      end

      def psql_version
        return unless psql_command.success?

        match = psql_command.read_stdout&.match(/psql \(PostgreSQL\) (.*)/)

        return unless match

        match[1].to_f
      end

      def psql_command
        @psql_command ||= Shellout.new(%w[psql --version])
      end

      def data_dir_version
        return unless File.exist?(data_dir_version_filename)

        @data_dir_version ||= File.read(data_dir_version_filename).to_f
      end

      def data_dir_version_filename
        @data_dir_version_filename ||= File.join(GDK::Config.new.postgresql.data_dir, 'PG_VERSION')
      end
    end
  end
end
