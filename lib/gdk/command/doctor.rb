# frozen_string_literal: true

module GDK
  module Command
    class Doctor < BaseCommand
      def initialize(diagnostics: GDK::Diagnostic.all, **args)
        @diagnostics = diagnostics

        super(**args)
      end

      def run(_ = [])
        unless installed?
          GDK::Output.warn("GDK has not been installed so cannot run 'gdk doctor'. Try running `gem install gitlab-development-kit` again.")
          return false
        end

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

      def installed?
        # TODO: Eventually, the Procfile will no longer exists so we need a better
        # way to determine this, but this will be OK for now.
        GDK.root.join('Procfile').exist?
      end

      def diagnostic_results
        @diagnostic_results ||= jobs.filter_map { |x| x.join[:results] }
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
        GDK::Output.success('Your GDK is healthy.')
      end

      def show_results
        GDK::Output.puts("\n")
        GDK::Output.warn('Your GDK may need attention.')

        diagnostic_results.each do |result|
          GDK::Output.puts(result)
        end
      end
    end
  end
end
