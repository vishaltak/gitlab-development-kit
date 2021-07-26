# frozen_string_literal: true

module GDK
  module Diagnostic
    class Praefect < Base
      TITLE = 'Praefect'
      MAX_PRAEFECT_INTERNAL_SOCKET_DIR_LENGTH = 80

      def diagnose
        nil
      end

      def success?
        dir_length_ok? && migrations_ok?
      end

      def detail
        return if success?

        output = []
        output << dir_length_too_long_message unless dir_length_ok?
        output << migrations_not_ok_message unless migrations_ok?

        output.join("\n#{diagnostic_detail_break}\n")
      end

      private

      def dir_length_ok?
        socket_dir_length <= MAX_PRAEFECT_INTERNAL_SOCKET_DIR_LENGTH
      end

      def dir_length_too_long_message
        <<~DIR_LENGTH_TOO_LONG_MESSAGE
          Praefect will attempt to create UNIX sockets in:

            #{socket_dir}

          UNIX socket creation issues have been observed when the character length of the
          directory above is < #{MAX_PRAEFECT_INTERNAL_SOCKET_DIR_LENGTH}, yours is #{socket_dir_length}.

          If you're experiencing issues, please try and reduce the directory depth to
          be under #{MAX_PRAEFECT_INTERNAL_SOCKET_DIR_LENGTH} characters.
        DIR_LENGTH_TOO_LONG_MESSAGE
      end

      def praefect_bin_path
        @praefect_bin_path ||= config.gitaly.__build_bin_path.join('praefect')
      end

      def praefect_config_path
        @praefect_config_path ||= config.gitaly.dir.join('praefect.config.toml')
      end

      def migrations_check_command
        @migrations_check_command ||= "#{praefect_bin_path} -config #{praefect_config_path} sql-migrate-status"
      end

      def migrations_needing_attention
        @migrations_needing_attention ||= begin
          Shellout.new(migrations_check_command).readlines.each_with_object([]) do |e, a|
            m = e.match(/\A\|\s(?<migration>[^\s]+)\s+\| (?:no|unknown migration)\s+\|\z/)
            next unless m

            a << m[:migration]
          end
        end
      end

      def migrations_ok?
        migrations_needing_attention.empty?
      end

      def migrations_not_ok_message
        <<~MIGRATIONS_NOT_OK_MESSAGE
          The following praefect DB migrations don't appear to have been applied:

            #{migrations_needing_attention.join("\n  ")}

          For full output you can run:

            #{migrations_check_command}
        MIGRATIONS_NOT_OK_MESSAGE
      end

      def socket_dir
        @socket_dir ||= config.praefect.internal_socket_dir
      end

      def socket_dir_length
        @socket_dir_length ||= socket_dir.to_s.length
      end
    end
  end
end
