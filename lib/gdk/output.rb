# frozen_string_literal: true

module GDK
  module Output
    COLOR_CODE_RED = '31'
    COLOR_CODE_GREEN = '32'
    COLOR_CODE_YELLOW = '33'
    COLOR_CODE_BLUE = '34'

    COLORS = {
      red: COLOR_CODE_RED,
      green: COLOR_CODE_GREEN,
      yellow: COLOR_CODE_YELLOW,
      blue: COLOR_CODE_BLUE,
      magenta: '35',
      cyan: '36',
      bright_red: '31;1',
      bright_green: '32;1',
      bright_yellow: '33;1',
      bright_blue: '34;1',
      bright_magenta: '35;1',
      bright_cyan: '36;1'
    }.freeze

    ICONS = {
      info: "\u2139\ufe0f ",    # requires an extra space
      success: "\u2705\ufe0f",
      warning: "\u26A0\ufe0f ", # requires an extra space
      error: "\u274C\ufe0f",
      debug: "\u26CF\ufe0f " # requires an extra space
    }.freeze

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      def color(index)
        COLORS.values[index % COLORS.size]
      end

      def ansi(code)
        "\e[#{code}m"
      end

      def reset_color
        ansi(0)
      end

      def wrap_in_color(message, color_code)
        return message unless colorize?

        ansi(color_code) + message + reset_color
      end

      def stdout_handle
        $stdout
      end

      def stderr_handle
        $stderr
      end

      def print(message = nil, stderr: false)
        stderr ? stderr_handle.print(message) : stdout_handle.print(message)
      end

      def puts(message = nil, stderr: false)
        stderr ? stderr_handle.puts(message) : stdout_handle.puts(message)
      end

      def divider(symbol: '-', length: 80, stderr: false)
        puts(symbol * length, stderr: stderr)
      end

      def notice(message)
        puts(notice_format(message))
      end

      def notice_format(message)
        "=> #{message}"
      end

      def info(message)
        puts(icon(:info) + message)
      end

      def warn(message)
        puts(icon(:warning) + wrap_in_color('WARNING', COLOR_CODE_YELLOW) + ": #{message}", stderr: true)
      end

      def debug(message)
        return unless GDK.config.gdk.__debug?

        puts(icon(:debug) + wrap_in_color('DEBUG', COLOR_CODE_BLUE) + ": #{message}", stderr: true)
      end

      def format_error(message)
        icon(:error) + wrap_in_color('ERROR', COLOR_CODE_RED) + ": #{message}"
      end

      def error(message)
        puts(format_error(message), stderr: true)
      end

      def abort(message)
        Kernel.abort(format_error(message))
      end

      def success(message)
        puts(icon(:success) + message)
      end

      def icon(code)
        return '' unless colorize?

        "#{ICONS[code]} "
      end

      def interactive?
        STDOUT.isatty # rubocop:disable Style/GlobalStdStream
      end

      def colorize?
        interactive? && ENV.fetch('NO_COLOR', '').empty?
      end

      def prompt(message)
        Kernel.print("#{message}: ")
        ARGF.gets.to_s.chomp
      rescue Interrupt
        ''
      end
    end

    extend ClassMethods
    include ClassMethods
  end
end
