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
    autoload :RedisCluster, 'gdk/services/redis_cluster'
    autoload :Required, 'gdk/services/required'
    autoload :Vault, 'gdk/services/vault'

    # This are the classes in Services modules that are used as base classes for services
    SERVICE_BASE_CLASSES = %i[
      Base
      Required
    ].freeze

    # Return a list of class names that represent a Service
    #
    # @return [Array<Symbol>] array of class names exposing a service
    def self.all_service_names
      ::GDK::Services.constants.select { |c| ::GDK::Services.const_get(c).is_a? Class } - SERVICE_BASE_CLASSES
    end

    # Returns an Array of all services, including enabled and not
    # enabled.
    #
    # @return [Array<Class>] all services
    def self.all
      all_service_names.map do |const|
        const_get(const).new
      end
    end

    # Return the service that matches the given name
    #
    # @param [Symbol|String] name
    # @return [::GDK::Services::Base|nil] service instance
    def self.fetch(name)
      service = all_service_names.find { |srv| srv == name.to_sym }

      return unless service

      const_get(service).new
    end

    # Returns an Array of enabled services only.
    #
    # @return [Array<Class>] enabled services
    def self.enabled
      all.select(&:enabled?)
    end
  end
end
