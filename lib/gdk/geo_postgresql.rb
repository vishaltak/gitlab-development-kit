# frozen_string_literal: true

module GDK
  class GeoPostgreSQL < PostgreSQL
    private

    def config
      @config ||= GDK.config.postgresql.geo
    end
  end
end
