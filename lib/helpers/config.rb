# frozen_string_literal: true

require 'erb'
require 'yaml'
require 'lib/helpers/output_helpers'

module Helpers
  class Config
    include Singleton
    include OutputHelpers

    attr_reader :root_path, :config_file

    def initialize
      @root_path = File.absolute_path(File.join(__FILE__, '../../../'))
      @config_file = File.join(@root_path, 'gdk.yml')
    end

    def config_exist?
      File.exist?(config_file)
    end

    def create_config!
      template_file = File.join(root_path, 'support/templates/gdk.yml.erb')
      erb = ERB.new(File.read(template))
      erb.filename = template_file

      yaml = erb.result(ConfigData.new)
      File.open(config_file, 'w') { |file| file.write(yaml) }
    end

    def config_data
      @config_data ||= begin
        unless config_exist?
          warn('There is no gdk.yml config file. Creating one with default attributes')

          create_config!
        end

        deep_symbolize_keys(YAML.load_file(config_file))
      end
    end

    private

    def deep_symbolize_keys(hash)
      hash.each_with_object({}) do |(key, value), mem|
        mem[key.to_sym] = value.is_a?(Hash) ? deep_symbolize_keys(value) : value
      end
    end
  end
end
