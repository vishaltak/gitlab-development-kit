# frozen_string_literal: true

module GDK
  class Messages
    attr_reader :messages

    def initialize
      @messages = parse_message_files
    end

    def render_all
      messages.each do |message|
        next unless message.render?

        GDK::Output.puts
        message.render
      end

      true
    end

    def add_message(header, body)
      messages << Message.new(header, body)
    end

    private

    attr_writer :messages

    def parse_message_files
      Dir.glob(GDK.config.__data_dir.join('messages/*.yml')).map { |f| Message.from_yaml(YAML.load_file(f)) }
    end
  end
end
