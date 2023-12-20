# frozen_string_literal: true

module GDK
  module Templates
    # Context to which a template is run
    #
    # This includes all available helper methods and data
    class Context
      attr_reader :locals

      def initialize(**locals)
        @locals = locals
      end

      # Return config data structure
      #
      # @return [GDK::Config] config data
      def config
        GDK.config
      end

      # Returns an instance of the service that matches the given name
      #
      # @return [GDK::Services::Base|nil]
      def service(name)
        GDK::Services.fetch(name)
      end

      def context_bindings
        binding
      end

      private

      def method_missing(method_name)
        return locals[method_name] if locals.include?(method_name)

        super
      end

      def respond_to_missing?(symbol, include_all)
        locals.any?(symbol) || super
      end
    end
  end
end
