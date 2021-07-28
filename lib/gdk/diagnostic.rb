# frozen_string_literal: true

module GDK
  module Diagnostic
    autoload :Base, 'gdk/diagnostic/base'
    autoload :Configuration, 'gdk/diagnostic/configuration'
    autoload :Dependencies, 'gdk/diagnostic/dependencies'
    autoload :Geo, 'gdk/diagnostic/geo'
    autoload :Gitlab, 'gdk/diagnostic/gitlab'
    autoload :Golang, 'gdk/diagnostic/golang'
    autoload :PendingMigrations, 'gdk/diagnostic/pending_migrations'
    autoload :PostgreSQL, 'gdk/diagnostic/postgresql'
    autoload :Praefect, 'gdk/diagnostic/praefect'
    autoload :Re2, 'gdk/diagnostic/re2'
    autoload :RubyGems, 'gdk/diagnostic/ruby_gems'
    autoload :RvmAndAsdf, 'gdk/diagnostic/rvm_and_asdf'
    autoload :StaleServices, 'gdk/diagnostic/stale_services'
    autoload :Status, 'gdk/diagnostic/status'
    autoload :Version, 'gdk/diagnostic/version'

    def self.all
      klasses = %i[
        RvmAndAsdf
        RubyGems
        Version
        Configuration
        Dependencies
        PendingMigrations
        PostgreSQL
        Geo
        Praefect
        Gitlab
        Status
        Re2
        Golang
        StaleServices
      ]

      klasses.map do |const|
        const_get(const).new
      end
    end
  end
end
