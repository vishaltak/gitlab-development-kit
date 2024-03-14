# frozen_string_literal: true

module GDK
  module Diagnostic
    class Redis < Base
      TITLE = "Redis"

      def success?
        versions_ok?
      end

      def detail
        return if success?

        output = []
        output << version_problem_message unless versions_ok?

        output.join("\n#{diagnostic_detail_break}\n")
      end

      private

      def versions_ok?
        asdf_redis_version == system_redis_version
      end

      def version_problem_message
        <<~MESSAGE
        Expected redis-server version '#{asdf_redis_version}' but found '#{system_redis_version}'
        MESSAGE
      end

      def system_redis_version
        @system_redis_version ||= Shellout.new(%q{redis-server --version | awk -F 'v=' '{ print $2 }' | awk '{ print $1 }'}).execute(display_output: false).read_stdout
      end

      def asdf_redis_version
        @asdf_redis_version ||= Shellout.new(%q{egrep "^redis " .tool-versions | awk '{ print $2 }'}).execute(display_output: false).read_stdout
      end

      def config
        @config ||= GDK.config
      end
    end
  end
end
