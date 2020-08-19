# frozen_string_literal: true

module GDK
  module Output
    COLOR_CODE_RED = '31'
    COLOR_CODE_GREEN = '32'
    COLOR_CODE_YELLOW = '33'

    COLORS = {
      red: COLOR_CODE_RED,
      green: COLOR_CODE_GREEN,
      yellow: COLOR_CODE_YELLOW,
      blue: '34',
      magenta: '35',
      cyan: '36',
      bright_red: '31;1',
      bright_green: '32;1',
      bright_yellow: '33;1',
      bright_blue: '34;1',
      bright_magenta: '35;1',
      bright_cyan: '36;1'
    }.freeze

    def self.color(index)
      COLORS.values[index % COLORS.size]
    end

    def self.ansi(code)
      "\e[#{code}m"
    end

    def self.reset_color
      ansi(0)
    end

    def self.wrap_in_color(message, color_code)
      ansi(color_code) + message + reset_color
    end

    def self.puts(message = nil, stderr: false)
      stderr ? Kernel.warn(message) : $stdout.puts(message)
    end

    def self.notice(message)
      puts("=> #{message}")
    end

    def self.warn(message)
      puts("\u26a0\ufe0f  " + wrap_in_color('WARNING', COLOR_CODE_YELLOW) + ": #{message}", stderr: true)
    end

    def self.error(message)
      puts("\u274C\ufe0f " + wrap_in_color('ERROR', COLOR_CODE_RED) + ": #{message}", stderr: true)
    end

    def self.success(message)
      puts("\u2705\ufe0f #{message}")
    end
  end
end
