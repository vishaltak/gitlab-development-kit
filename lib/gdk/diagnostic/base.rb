# frozen_string_literal: true

require 'stringio'
require 'socket'

module GDK
  module Diagnostic
    class Base
      def diagnose
        raise NotImplementedError
      end

      def success?
        raise NotImplementedError
      end

      def message(content = detail)
        raise NotImplementedError unless title

        <<~MESSAGE

          #{title}
          #{diagnostic_header}
          #{content}
        MESSAGE
      end

      def detail
        ''
      end

      def title
        self.class::TITLE
      end

      private

      def diagnostic_header
        @diagnostic_header ||= '=' * 80
      end

      def diagnostic_detail_break
        @diagnostic_detail_break ||= '-' * 80
      end

      def config
        @config ||= GDK::Config.new
      end

      def remove_socket_file(path)
        File.unlink(path) if File.exist?(path) && File.socket?(path)
      end

      def can_create_socket?(path)
        result = true
        remove_socket_file(path)
        UNIXServer.new(path)
        result
      rescue ArgumentError => e
        raise e unless e.to_s.include?('too long unix socket path')

        result = false
      ensure
        remove_socket_file(path)
        result
      end
    end
  end
end
