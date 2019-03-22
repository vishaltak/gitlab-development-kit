# frozen_string_literal: true

module Helpers
  module OutputHelpers
    def notice(message)
      puts "=> #{message}"
    end

    def warn(message)
      puts "(!) WARNING: #{message}"
    end

    def error(message)
      puts "(❌) Error: #{message}"
    end

    def confirmation(message)
      puts "(✔) #{message}"
    end
  end
end
