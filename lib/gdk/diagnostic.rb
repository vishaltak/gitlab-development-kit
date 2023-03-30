# frozen_string_literal: true

module GDK
  module Diagnostic
    autoload :Asdf, 'gdk/diagnostic/asdf'
    autoload :Base, 'gdk/diagnostic/base'
    autoload :Bundler, 'gdk/diagnostic/bundler'
    autoload :Configuration, 'gdk/diagnostic/configuration'
    autoload :Dependencies, 'gdk/diagnostic/dependencies'
    autoload :Geo, 'gdk/diagnostic/geo'
    autoload :Gitaly, 'gdk/diagnostic/gitaly'
    autoload :Gitlab, 'gdk/diagnostic/gitlab'
    autoload :Golang, 'gdk/diagnostic/golang'
    autoload :MacPorts, 'gdk/diagnostic/mac_ports'
    autoload :PGUser, 'gdk/diagnostic/pguser'
    autoload :PendingMigrations, 'gdk/diagnostic/pending_migrations'
    autoload :PostgreSQL, 'gdk/diagnostic/postgresql'
    autoload :Praefect, 'gdk/diagnostic/praefect'
    autoload :RubyGems, 'gdk/diagnostic/ruby_gems'
    autoload :RvmAndAsdf, 'gdk/diagnostic/rvm_and_asdf'
    autoload :StaleServices, 'gdk/diagnostic/stale_services'
    autoload :Status, 'gdk/diagnostic/status'
    autoload :Version, 'gdk/diagnostic/version'

    def self.all
      klasses = %i[
        RvmAndAsdf
        MacPorts
        RubyGems
        Bundler
        Version
        Configuration
        Dependencies
        PendingMigrations
        PostgreSQL
        PGUser
        Geo
        Praefect
        Gitaly
        Gitlab
        Status
        Golang
        StaleServices
      ]

      klasses.map do |const|
        const_get(const).new
      end
    end
  end
end
