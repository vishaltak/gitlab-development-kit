# frozen_string_literal: true

module GDK
  module Command
    class Measure
      def initialize(stdout: $stdout, stderr: $stderr)
        @stdout = stdout
        @stderr = stderr
      end

      def run(argv)
        if argv.empty?
          stderr.puts 'Please add a local URL as argument (e.g. http://localhost:3000/explore or /explore)'
          exit
        else
          # Check if GDK is running


          # Check if docker installed and running
          

          # Check and transform args URLs into docker host format
          @localUrls = []
          argv.map do |localUrl|
            stdout.puts 'LOCAL ' + localUrl
            localUrl = 'http://host.docker.internal:3000' + localUrl
            @localUrls.push(localUrl)
          end
          stdout.puts 'Starting Sitespeed measurements for ' + @localUrls.join(', ')

          # Create folder name from git repo + time


          # Start Sitespeed through docker
          @dockerCommand = 'docker run --shm-size 2g --rm -v "$(pwd):/sitespeed.io" sitespeedio/sitespeed.io:14.2.3 -b chrome '
          # 5 repetitions
          @dockerCommand += '-n 1 '
          # Deactivate the performance bar as it slows the measurements down
          @dockerCommand += '--cookie perf_bar_enabled=false '
          @dockerCommand += '--outputFolder sitespeed-result/folder '
          @dockerCommand += @localUrls.join(' ')

          @command = Shellout.new(@dockerCommand)
          @command.run
          stdout.puts @command.read_stdout

          # Open directly browser with new report

        end
      end

      private

      attr_reader :stdout, :stderr
    end
  end
end
