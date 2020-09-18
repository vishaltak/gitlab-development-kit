# frozen_string_literal: true

require 'fileutils'

module GDK
  class PostgresqlGeoPrimary < Postgresql
    PathNotSpecified = Class.new(StandardError)

    class PrimaryConfig < ::GDK::Config
      GDK_ROOT = GDK.config.geo.primary_path
      FILE = GDK.config.geo.primary_path&.join('gdk.yml')
    end

    def initialize
      raise PathNotSpecified, 'geo.primary_path is not specified' unless PrimaryConfig::GDK_ROOT&.exist?

      super
    end

    def config
      @config ||= PrimaryConfig.new.postgresql
    end
  end
end
