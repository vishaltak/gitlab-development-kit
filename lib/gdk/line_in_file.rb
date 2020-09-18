# frozen_string_literal: true

module GDK
  class LineInFile
    attr_accessor :path

    def initialize(path)
      @path = path
    end

    def append(line: nil, regexp: nil)
      File.open(path, 'a+') do |file|
        regexp ||= Regexp.new(line)

        break if regexp && file.readlines.find { |l| l =~ regexp }

        file.write(line) if line
        file.write(yield) if block_given?
      end
    end

    def remove(regexp:)
      lines = File.readlines(path).reject { |l| l =~ regexp }

      File.open(path, 'w') do |file|
        file.write(*lines)
      end
    end
  end
end
