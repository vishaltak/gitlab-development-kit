# frozen_string_literal: true

require 'time'

module GDK
  module Command
    class Measure
      def initialize(stdout: $stdout, stderr: $stderr)
        @stdout = stdout
        @stderr = stderr
      end

      def run(argv)
        if argv.empty?
          stderr.puts 'Please add a URL as argument (e.g. http://localhost:3000/explore, /explore or https://gitlab.com/explore)'
          exit
        else
          # Check if docker installed and running
          unless docker_running?
            stderr.puts 'ERROR: Docker is not installed or running!'
            exit
          end

          # Check and transform args URLs into docker host format
          local_urls = []
          @has_local_url = false
          argv.map do |localurl|
            # Transform local relative URL's
            if localurl.start_with? '/'
              localurl = "#{GDK.config.__uri}#{localurl}"
              @has_local_url = true
            end

            localurl = localurl.gsub('localhost', 'host.docker.internal')
            localurl = localurl.gsub('127.0.0.1', 'host.docker.internal')

            local_urls.push(localurl)
          end

          # Check if GDK is running if local URL
          if @has_local_url && !gdk_running?
            stderr.puts "ERROR: GDK is not running locally on #{GDK.config.__uri}!"
            exit
          end

          # Getting a folder name with branch name (if local stats) and time
          save_folder = report_folder_name

          stdout.puts "Starting Sitespeed measurements for #{local_urls.join(', ')}"

          # Start Sitespeed through docker
          docker_command = 'docker run --cap-add=NET_ADMIN --shm-size 2g --rm -v "$(pwd):/sitespeed.io" sitespeedio/sitespeed.io:14.2.3 -b chrome '
          # 4 repetitions
          docker_command += '-n 4 '
          # Limit Cable Connection
          docker_command += '-c cable '
          # Deactivate the performance bar as it slows the measurements down
          docker_command += '--cookie perf_bar_enabled=false '
          docker_command += "--outputFolder sitespeed-result/#{save_folder} "
          docker_command += local_urls.join(' ')

          command = Shellout.new(docker_command)
          command.stream

          # Open directly browser with new report
          stdout.puts "Opening Report open ./sitespeed_result/#{save_folder}/index.html"
          Shellout.new("open ./sitespeed-result/#{save_folder}/index.html").run
        end
      end

      private

      attr_reader :stdout, :stderr

      def gdk_running?
        curl_result = Shellout.new("curl -sL -w '%{http_code}' '#{GDK.config.__uri}' -o /dev/null").run
        curl_result == '200'
      end

      def docker_running?
        docker_check = Shellout.new('docker info')
        docker_check.run
        docker_check.success?
      end

      def report_folder_name
        folder_name = @has_local_url ? Shellout.new('git rev-parse --abbrev-ref HEAD', chdir: GDK.config.gitlab.dir).run : 'external'
        folder_name + "_#{Time.new.strftime('%F-%H-%M-%S')}"
      end
    end
  end
end
