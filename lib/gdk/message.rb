# frozen_string_literal: true

require 'yaml'

module GDK
  class Message
    VALID_FILENAME_REGEX = /\A\d{4}_\w+\.yml/.freeze

    attr_reader :header, :body

    FilenameInvalidError = Class.new(StandardError)

    def initialize(filepath, header, body)
      @filepath = Pathname.new(filepath)
      raise FilenameInvalidError unless filename_valid?

      @header = header
      @body = body
      @cache_file_contents = read_cache_file_contents
    end

    def self.from_file(filepath)
      yaml = YAML.safe_load(filepath.read)
      new(filepath, yaml['header'], yaml['body'])
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

    attr_reader :filepath
    attr_accessor :cache_file_contents

    def filename_valid?
      filepath.basename.to_s.match?(VALID_FILENAME_REGEX)
    end

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
      @message_unique_identifier ||= filepath.basename.to_s[0..3]
    end

    def cache_file
      @cache_file ||= config.__cache_dir.join('.gdk-messages.yml')
    end

    def read_cache_file_contents
      cache_file.exist? ? YAML.safe_load(cache_file.read) : {}
    end
  end
end
