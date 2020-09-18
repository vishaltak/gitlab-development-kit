# frozen_string_literal: true

pg_namespace = namespace :postgresql do
  def postgresql
    @postgresql ||= GDK::Postgresql.new
  end

  task :reconfigure do
    postgresql.reconfigure
  end

  namespace :geo do
    task :reconfigure do
      GDK::PostgresqlGeo.new.reconfigure
    end

    task :replicate do
      require 'gdk/postgresql_replication'
      require 'gdk/postgresql_geo_primary'

      geo_primary_postgresql = GDK::PostgresqlGeoPrimary.new

      GDK::PostgresqlReplication.new(primary: geo_primary_postgresql).setup

      pg_namespace[:reconfigure].invoke
    end
  end
end
