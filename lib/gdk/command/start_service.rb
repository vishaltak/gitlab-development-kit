module GDK
  module Command
    class StartService < BaseCommand
      def initialize(service)
        @cmd = %W[gdk start #{service}]
        @recover_cmd = %W[gdk restart #{service}]
        @description = "Starting #{service}"
      end
    end
  end
end
