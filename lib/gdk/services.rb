# frozen_string_literal: true

require_relative 'services/base'
require_relative 'services/required'
require_relative 'services/redis'
require_relative 'services/postgresql'
require_relative 'services/postgresql_replica'
require_relative 'services/minio'
require_relative 'services/openldap'
require_relative 'services/gitlab_workhorse'

module GDK
  # Services module contains individual service classes (e.g. Redis) that
  # are responsible for producing the correct command line to execute and
  # if the service should in fact be executed.
  #
  module Services
    ALL = %i[
      Redis
      PostgreSQL
      PostgreSQLReplica
      Minio
      OpenLDAP
      GitLabWorkhorse
    ].freeze

    # Returns an Array of enabled services only.
    #
    # @return [Array<Class>] enabled services
    def self.enabled
      ALL.each_with_object([]) do |const, all|
        instance = const_get(const).new
        next unless instance.enabled?

        all << instance
      end
    end
  end
end
