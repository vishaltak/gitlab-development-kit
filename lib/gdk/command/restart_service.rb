module GDK
  module Command
    class RestartService < BaseCommand
      def initialize(service)
        @cmd = %W[gdk restart #{service}]
        @description = "Restarting #{service}"
      end
    end
  end
end
