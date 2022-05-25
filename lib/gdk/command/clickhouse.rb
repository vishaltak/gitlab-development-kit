# frozen_string_literal: true

module GDK
  module Command
    # Executes clickhouse client command with configured connection paras and any provided extra arguments
    class Clickhouse < BaseCommand
      def run(args = [])
        unless GDK.config.clickhouse.enabled?
          GDK::Output.error('Clickhouse is not enabled. Please check your gdk.yml configuration')

          exit(-1)
        end

        exec(*GDK::Clickhouse.new.client_cmd(args), chdir: GDK.root)
      end
    end
  end
end
