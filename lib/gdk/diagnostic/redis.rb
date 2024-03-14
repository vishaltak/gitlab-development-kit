# frozen_string_literal: true

module GDK
  module Diagnostic
    class Redis < Base
      TITLE = 'Redis'

      def success?
        cmd_version == req_version
      end

      def detail
        ''
      end

      def cmd_version
        redis_version || 'unknown'
      end

      def req_version
        required_version || 'unknown'
      end

      def message(content = detail)
        <<~MESSAGE
          Redis version #{cmd_version} does not match the expected version #{req_version} in .tool-versions.
          Please check your `PATH` for Redis with `which redis-server`. You can update your PATH to point to the correct version if necessary.

        MESSAGE
      end

      private

      def redis_version
        match = redis_command.read_stdout&.match(/Redis\Wserver\Wv=(.*)\Wsha=/)

        return unless match

        match[1]
      end

      def required_version
        match = required_command.read_stdout&.match(/redis\s+(\d+\.\d+\.\d+)/)

        return unless match

        match[1].strip
      end

      def redis_command
        @redis_command ||= begin
                            Shellout.new(%W[redis-server --version]).execute(display_output: false, display_error: false)
                          end
      end

      def required_command
        @required_command ||= begin
                             Shellout.new(%W[asdf current]).execute(display_output: false, display_error: false)
                           end
      end
    end
  end
end
