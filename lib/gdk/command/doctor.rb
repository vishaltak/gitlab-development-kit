# frozen_string_literal: true

module GDK
  module Command
    class Doctor < BaseCommand
      def initialize(diagnostics: GDK::Diagnostic.all, **args)
        @diagnostics = diagnostics

        super(**args)
      end

      def run(_ = [])
        start_necessary_services

        if diagnostic_results.empty?
          show_healthy

          true
        else
          show_results

          false
        end
      end

      private

      attr_reader :diagnostics

      def diagnostic_results
        @diagnostic_results ||= jobs.map { |x| x.join[:results] }.compact
      end

      def jobs
        diagnostics.map do |diagnostic|
          Thread.new do
            Thread.current[:results] = perform_diagnosis_for(diagnostic)
            GDK::Output.print('.', stderr: true)
          end
        end
      end

      def perform_diagnosis_for(diagnostic)
        diagnostic.diagnose
        diagnostic.message unless diagnostic.success?
      rescue StandardError => e
        diagnostic.message(([e.message] + e.backtrace).join("\n"))
      end

      def start_necessary_services
        Runit.start('postgresql', quiet: true)
        # Give services a chance to start up..
        sleep(2)
      end

      def show_healthy
        GDK::Output.puts("\n")
        GDK::Output.success('GDK is healthy.')
      end

      def show_results
        GDK::Output.puts("\n")
        GDK::Output.warn('GDK may need attention.')

        diagnostic_results.each do |result|
          GDK::Output.puts(result)
        end
      end
    end
  end
end
