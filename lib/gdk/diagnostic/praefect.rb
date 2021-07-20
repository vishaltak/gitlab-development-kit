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
        socket_dir_length <= MAX_PRAEFECT_INTERNAL_SOCKET_DIR_LENGTH
      end

      def detail
        return if success?

        <<~GITALY_DIR_LENGTH_MSG
          Praefect will attempt to create UNIX sockets in:

            #{socket_dir}

          UNIX socket creation issues have been observed when the character length of the
          directory above is < #{MAX_PRAEFECT_INTERNAL_SOCKET_DIR_LENGTH}, yours is #{socket_dir_length}.

          If you're experiencing issues, please try and reduce the directory depth to
          be under #{MAX_PRAEFECT_INTERNAL_SOCKET_DIR_LENGTH} characters.
        GITALY_DIR_LENGTH_MSG
      end

      private

      def socket_dir
        @socket_dir ||= config.praefect.internal_socket_dir
      end

      def socket_dir_length
        @socket_dir_length ||= socket_dir.to_s.length
      end
    end
  end
end
