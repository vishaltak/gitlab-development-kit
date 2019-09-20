module GDK
  module Command
    class RestartService < BaseCommand
      def initialize(service)
        @cmd = %W[gdk restart #{service}]

        @recover_cmd = %W[sv force-restart #{File.join('.', 'sv', service)}]
        @description = "Restarting #{service}"
      end
    end
  end
end
