# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk tail` command execution
    #
    # This command accepts the following subcommands:
    # - --help
    class Tail < BaseCommand
      OUTPUT = <<~MSG
        Usage: gdk tail [[--help] | [<log_or_shortcut>[ <...>]]

        Tail command:

          gdk tail                                                  # Tail all log files (stdout and stderr only)
          gdk tail <log_or_shortcut>[ <...>]                        # Tail specified log files (stdout and stderr only)
          gdk tail --help                                           # Print this help text

        Available logs:

          %<logs>s

        Shortcuts:

          %<shortcuts>s

        To contribute to GitLab, see
        https://docs.gitlab.com/ee/development/index.html.
      MSG

      def run(args = [])
        return print_help if (args & ['--help', '-h']).any?

        Runit.tail(args)
      end

      private

      def print_help
        aligned_logs = Runit::LOG_DIR.children.map(&:basename).sort.join("\n  ")

        # Keep inline with `Tail command:`
        width = [Runit::SERVICE_SHORTCUTS.keys.max_by(&:length).length + 20, 57].max
        shortcuts = Runit::SERVICE_SHORTCUTS.map { |sc| format("%-#{width}s # %s", *sc) }
        aligned_shortcuts = shortcuts.sort.join("\n  ")

        output = format(OUTPUT, logs: aligned_logs, shortcuts: aligned_shortcuts)

        GDK::Output.puts(output)

        true
      end
    end
  end
end
