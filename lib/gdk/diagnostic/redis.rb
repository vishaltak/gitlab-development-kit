# frozen_string_literal: true

require_relative '../../asdf/tool_versions'

module GDK
  module Diagnostic
    class Redis < Base
      TITLE = 'Redis'

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
        detected_redis_version == expected_redis_version
      end

      def version_problem_message
        <<~MESSAGE
          Redis version #{detected_redis_version} does not match the expected version #{expected_redis_version} in .tool-versions.

          Please check your `PATH` for Redis with `which redis-server`. You can update your PATH to point to the correct version if necessary.
        MESSAGE
      end

      def expected_redis_version
        @expected_redis_version ||= ::Asdf::ToolVersions.new.default_version_for('redis')
      end

      def detected_redis_version
        @detected_redis_version ||= begin
          sh = ::Shellout.new('redis-server --version').execute(display_output: false, display_error: false)

          if sh.success?
            sh.read_stdout.match(/Redis server v=(?<version>.+) sha=/)[:version]
          else
            'UNKNOWN'
          end
        end
      end
    end
  end
end
