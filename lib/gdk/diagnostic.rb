# frozen_string_literal: true

module GDK
  module Diagnostic
    autoload :Asdf, 'gdk/diagnostic/asdf'
    autoload :Base, 'gdk/diagnostic/base'
    autoload :Bundler, 'gdk/diagnostic/bundler'
    autoload :Chromedriver, 'gdk/diagnostic/chromedriver'
    autoload :Configuration, 'gdk/diagnostic/configuration'
    autoload :Dependencies, 'gdk/diagnostic/dependencies'
    autoload :Environment, 'gdk/diagnostic/environment'
    autoload :FileWatches, 'gdk/diagnostic/file_watches'
    autoload :Geo, 'gdk/diagnostic/geo'
    autoload :Gitaly, 'gdk/diagnostic/gitaly'
    autoload :Gitlab, 'gdk/diagnostic/gitlab'
    autoload :Golang, 'gdk/diagnostic/golang'
    autoload :Hostname, 'gdk/diagnostic/hostname'
    autoload :MacPorts, 'gdk/diagnostic/mac_ports'
    autoload :Nginx, 'gdk/diagnostic/nginx'
    autoload :PGUser, 'gdk/diagnostic/pguser'
    autoload :PendingMigrations, 'gdk/diagnostic/pending_migrations'
    autoload :PostgreSQL, 'gdk/diagnostic/postgresql'
    autoload :Praefect, 'gdk/diagnostic/praefect'
    autoload :Re2, 'gdk/diagnostic/re2'
    autoload :RubyGems, 'gdk/diagnostic/ruby_gems'
    autoload :RvmAndAsdf, 'gdk/diagnostic/rvm_and_asdf'
    autoload :StaleData, 'gdk/diagnostic/stale_data'
    autoload :StaleServices, 'gdk/diagnostic/stale_services'
    autoload :Status, 'gdk/diagnostic/status'
    autoload :Version, 'gdk/diagnostic/version'

    def self.all
      klasses = %i[
        Geo
      ]

      klasses.map do |const|
        const_get(const).new
      end
    end
  end
end
