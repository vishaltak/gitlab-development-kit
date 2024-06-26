# frozen_string_literal: true

module GDK
  module Services
    InvalidEnvironmentKeyError = Class.new(StandardError)

    # @abstract Base class to be used by individual service classes.
    #
    class Base
      def initialize
        validate_env_keys!
      end

      # Name of the service
      #
      # @abstract to be implemented by the subclass
      # @return [String] name
      def name
        raise NotImplementedError
      end

      # Command to execute the service
      #
      # @abstract to be implemented by the subclass
      # @return [String] command
      def command
        raise NotImplementedError
      end

      # Is service enabled?
      #
      # @return [Boolean] whether is enabled or not
      def enabled?
        false
      end

      # Environment variables
      #
      # @return [Hash] a hash of environment variables that need to be set for
      # this service.
      def env
        {}
      end

      # Entry to be used in Procfile.
      #
      # @return [String] in the format expected used in Procfiles.
      def procfile_entry
        cmd = []
        cmd << '#' unless enabled?

        cmd += %W[#{name}: exec]
        if env.any?
          cmd << '/usr/bin/env'
          cmd += env.map { |k, v| "#{k}=\"#{v}\"" }
        end

        cmd << command
        cmd.join(' ')
      end

      private

      def validate_env_keys!
        env.reject { |k, _| k =~ /^[A-Z_]+$/ }.tap do |invalid|
          break unless invalid.any?

          raise InvalidEnvironmentKeyError, "Invalid environment keys for '#{name}': #{invalid.keys}"
        end
      end

      def config
        GDK.config
      end
    end
  end
end
