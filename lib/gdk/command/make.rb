module GDK
  module Command
    class Make < BaseCommand
      def initialize(job, recover_cmd: [], desc: nil)
        @cmd = %W[make #{job}]
        @recover_cmd = recover_cmd
        @description = desc || "Running make #{job}"
      end
    end
  end
end
