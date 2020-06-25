# frozen_string_literal: true

module GDK
  class PostgresqlGeo < Postgresql
    private

    def config
      @config ||= GDK.config.postgresql.geo
    end
  end
end
