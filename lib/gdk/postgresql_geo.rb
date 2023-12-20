# frozen_string_literal: true

module GDK
  class PostgresqlGeo < Postgresql
    private

    def postgresql_config
      @postgresql_config ||= config.postgresql.geo
    end

    def default_database
      'gitlabhq_geo_development'
    end
  end
end
