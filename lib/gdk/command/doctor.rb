# frozen_string_literal: true

module GDK
  module Command
    class Doctor
      def initialize(diagnostics_serial: GDK::Diagnostic.serial_classes,
                     diagnostics_parallel: GDK::Diagnostic.parallel_classes,
                     stdout: $stdout, stderr: $stderr)
        @diagnostics_serial = diagnostics_serial
        @diagnostics_parallel = diagnostics_parallel
        @stdout = stdout
        @stderr = stderr
      end

      def run
        start_necessary_services

        if diagnostic_results.empty?
          show_healthy
        else
          show_results
        end
      end

      private

      attr_reader :diagnostics, :stdout, :stderr

      def diagnostic_results
        return @diagnostic_results if @diagnostic_results

        serial = @diagnostics_serial.map do |diagnostic|
          perform_diagnosis_for(diagnostic)
        end
        parallel = jobs.map { |x| x.join[:results] }.compact

        @diagnostic_results = serial + parallel
      end

      def jobs
        @diagnostics_parallel.map do |diagnostic|
          Thread.new do
            Thread.current[:results] = perform_diagnosis_for(diagnostic)
          end
        end
      end

      def perform_diagnosis_for(diagnostic)
        diagnostic.diagnose
        diagnostic.message unless diagnostic.success?
      end

      def start_necessary_services
        Shellout.new('gdk start postgresql').run
      end

      def show_healthy
        stdout.puts 'GDK is healthy.'
      end

      def show_results
        stdout.puts warning
        diagnostic_results.each do |result|
          stdout.puts result
        end
      end

      def warning
        <<~WARNING
          #{'=' * 80}
          Please note these warning only exist for debugging purposes and can
          help you when you encounter issues with GDK.
          If your GDK is working fine, you can safely ignore them. Thanks!
          #{'=' * 80}

        WARNING
      end
    end
  end
end
