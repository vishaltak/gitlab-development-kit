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
        dir_length_ok?
      end

      def detail
        return if success?

        dir_length_too_long_message unless dir_length_ok?
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
