# frozen_string_literal: true

require 'stringio'

module GDK
  class OutputBuffered
    include GDK::Output

    def initialize
      @output = StringIO.new
    end

    def stdout_handle
      output
    end

    def stderr_handle
      output
    end

    def dump
      output.string
    end

    private

    attr_reader :output
  end
end
