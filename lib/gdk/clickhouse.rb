# frozen_string_literal: true

module GDK
  # Provides ClickHouse utility methods
  class Clickhouse
    def client_cmd(args = [])
      cmd = [config.bin.to_s]
      cmd << 'client'
      cmd << "--port=#{config.tcp_port}"
      (cmd + args).flatten
    end

    private

    def config
      @config ||= GDK.config.clickhouse
    end
  end
end
