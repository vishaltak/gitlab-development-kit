# frozen_string_literal: true

module GDK
  # Services module contains individual service classes (e.g. Redis) that
  # are responsible for producing the correct command line to execute and
  # if the service should in fact be executed.
  #
  module Services
    autoload :Base, 'gdk/services/base'
    autoload :Clickhouse, 'gdk/services/clickhouse'
    autoload :GitLabWorkhorse, 'gdk/services/gitlab_workhorse'
    autoload :Minio, 'gdk/services/minio'
    autoload :OpenLDAP, 'gdk/services/openldap'
    autoload :PostgreSQL, 'gdk/services/postgresql'
    autoload :PostgreSQLReplica, 'gdk/services/postgresql_replica'
    autoload :Redis, 'gdk/services/redis'
    autoload :Required, 'gdk/services/required'
    autoload :Vault, 'gdk/services/vault'

    ALL = %i[
      Clickhouse
      GitLabWorkhorse
      Minio
      OpenLDAP
      PostgreSQL
      PostgreSQLReplica
      Redis
      Vault
    ].freeze

    # Returns an Array of all services, including enabled and not
    # enabled.
    #
    # @return [Array<Class>] all services
    def self.all
      ALL.map do |const|
        const_get(const).new
      end
    end

    # Returns an Array of enabled services only.
    #
    # @return [Array<Class>] enabled services
    def self.enabled
      all.select(&:enabled?)
    end
  end
end
