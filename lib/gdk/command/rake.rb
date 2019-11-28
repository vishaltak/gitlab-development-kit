module GDK
  module Command
    class Rake < BaseCommand
      def initialize(job, recover_cmd: [], desc: nil)
        @cmd = %W[rake #{job}]
        @recover_cmd = recover_cmd
        @description = desc || "Running rake #{job}"
      end
    end
  end
end
