# frozen_string_literal: true

module GDK
  # Provides ClickHouse utility methods
  class Clickhouse
    VERSION_REGEXP = /ClickHouse (?:client|server) version (?<version>[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/.freeze

    def client_cmd(args = [])
      cmd = [config.bin.to_s]
      cmd << 'client'
      cmd << "--port=#{config.tcp_port}"
      (cmd + args).flatten
    end

    def installed?
      File.exist?(config.bin)
    end

    def current_version
      return unless installed?

      output = Shellout.new(config.bin.to_s, 'server', '--version').try_run.strip.chomp
      matched = output.match(VERSION_REGEXP)

      matched[:version]
    end

    private

    def config
      @config ||= GDK.config.clickhouse
    end
  end
end
