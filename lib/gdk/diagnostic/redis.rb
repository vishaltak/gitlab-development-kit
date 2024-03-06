# frozen_string_literal: true

module GDK
  module Diagnostic
    class Redis < Base
      TITLE = 'Redis'

      def success?
        versions_match?
      end

      def detail
        return if success?

        <<~MESSAGE
          Redis version #{redis_server_version} does not match the expected version #{redis_tool_version} in .tool-versions.
          Please run `asdf install redis #{redis_tool_version}` or use a package manager of your choice to install the correct version.
        MESSAGE
      end

      def versions_match?
        redis_server_version == redis_tool_version
      end

      def redis_server_version_command
        @redis_server_version_command ||= Shellout.new('redis-server --version').execute(display_output: false, display_error: false)
      end

      def redis_server_version
        return unless redis_server_version_command.success?

        @redis_server_version ||= redis_server_version_command.read_stdout&.match(/v=([\d.]+)/)[1]
      end

      def redis_tool_version
        ::Asdf::ToolVersions.new.default_version_for('redis')
      end
    end
  end
end
