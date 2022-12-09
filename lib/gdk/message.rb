# frozen_string_literal: true

require 'openssl'
require 'yaml'

module GDK
  class Message
    attr_reader :header, :body

    def initialize(header, body)
      @header = header
      @body = body
      @cache_file_contents = read_cache_file_contents
    end

    def self.from_yaml(yaml)
      new(yaml['header'], yaml['body'])
    end

    def render?
      cache_file_contents[message_unique_identifier] != true
    end

    def render
      return unless render?

      display
      cache_message_rendered
    end

    private

    attr_accessor :cache_file_contents

    def config
      @config ||= GDK.config
    end

    def display
      GDK::Output.info(header)
      GDK::Output.divider
      GDK::Output.puts(body)
    end

    def cache_message_rendered
      cache_file_contents[message_unique_identifier] = true

      update_cached_file
    end

    def update_cached_file
      config.__cache_dir.mkpath
      cache_file.open('w') { |f| f.write(cache_file_contents.to_yaml) }
    end

    def message_unique_identifier
      @message_unique_identifier ||= OpenSSL::Digest::SHA256.hexdigest(header + body)
    end

    def cache_file
      @cache_file ||= config.__cache_dir.join('.gdk-messages.yml')
    end

    def read_cache_file_contents
      cache_file.exist? ? YAML.safe_load(cache_file.read) : {}
    end
  end
end
