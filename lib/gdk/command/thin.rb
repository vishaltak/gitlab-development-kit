# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk thin` command execution
    class Thin < BaseCommand
      def run(args = [])
        GDK::Output.puts "gdk thin is deprecated. Use 'gdk rails s' instead."

        false
      end
    end
  end
end
