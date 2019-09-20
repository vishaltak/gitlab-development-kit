module GDK
  module Command
    class Git < BaseCommand
      attr_reader :working_directory

      def initialize(args, repo:, desc:)
        @cmd = %w[git] + args
        @working_directory = repo
        @description = desc

        # Retry 2 times by setting the recover command to the original command
        @recover_cmd = @cmd
      end
    end
  end
end
