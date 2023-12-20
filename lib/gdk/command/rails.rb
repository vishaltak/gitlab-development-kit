# frozen_string_literal: true

module GDK
  module Command
    # Handles `gdk rails <command> [<args>]` command execution
    class Rails < BaseCommand
      def run(args = [])
        GDK::Output.abort('Usage: gdk rails <command> [<args>]') if args.empty?

        execute_command!(args)
      end

      private

      def execute_command!(args)
        exec(
          { 'RAILS_ENV' => 'development' },
          *generate_command(args),
          chdir: GDK.root.join('gitlab')
        )
      end

      def generate_command(args)
        %w[../support/bundle-exec rails] + args
      end
    end
  end
end
