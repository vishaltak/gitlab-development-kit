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

    private

    attr_writer :messages

    def parse_message_files
      Dir.glob(GDK.config.__data_dir.join('messages/*.yml')).map { |f| message_from_file(f) }.compact
    end

    def message_from_file(filepath)
      Message.from_file(Pathname.new(filepath))
    rescue Message::FilenameInvalidError
      GDK::Output.warn("Ignoring #{f} as it's invalid.")
      nil
    end
  end
end
