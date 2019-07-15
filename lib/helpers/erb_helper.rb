# frozen_string_literal: true

require 'json'

module Helpers
  class ConfigData
    def initialize(repositories = {})
      @repositories = repositories
    end

    def value_or_default(value, default)
      (value || default).to_json
    end

    # ERB will call this to get access to the class
    def get_binding
      binding
    end
  end
end
