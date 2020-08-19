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
          docker_check = Shellout.new('docker info')
          docker_check.run
          unless docker_check.success?
            stderr.puts 'ERROR: Docker is not installed or running!'
            exit
          end

          # Check and transform args URLs into docker host format
          local_urls = []
          @has_local_url = false
          argv.map do |localurl|
            # Transform local relative URL's
            if localurl.start_with? '/'
              localurl = "http://host.docker.internal:3000#{localurl}"
              @has_local_url = true
            end

            localurl.gsub('localhost', 'host.docker.internal')
            localurl.gsub('127.0.0.1', 'host.docker.internal')

            local_urls.push(localurl)
          end

          # Check if GDK is running if local URL
          if @has_local_url
            curl_result = Shellout.new("curl -sL -w '%{http_code}' '#{GDK.config.__uri}' -o /dev/null").run
            unless curl_result == '200'
              stderr.puts "ERROR: GDK is not running locally on #{GDK.config.__uri} (Response: #{curl_result}!"
              exit
            end
          end

          # Create folder name from gitlab repo + time
          if @has_local_url
            @gl_branchname = Shellout.new('git rev-parse --abbrev-ref HEAD', chdir: GDK.config.gitlab.dir).run
            @folder_name = @gl_branchname
          else
            @folder_name = 'external'
          end
          @folder_name += "_#{Time.new.strftime('%F-%H-%M-%S')}"

          stdout.puts "Starting Sitespeed measurements for #{local_urls.join(', ')}"

          # Start Sitespeed through docker
          @docker_command = 'docker run --cap-add=NET_ADMIN --shm-size 2g --rm -v "$(pwd):/sitespeed.io" sitespeedio/sitespeed.io:14.2.3 -b chrome '
          # TODO: 5 repetitions
          @docker_command += '-n 1 '
          # TODO: Limit Cable Connection
          @docker_command += '-c cable '
          # Deactivate the performance bar as it slows the measurements down
          @docker_command += '--cookie perf_bar_enabled=false '
          @docker_command += "--outputFolder sitespeed-result/#{@folder_name} "
          @docker_command += local_urls.join(' ')

          @command = Shellout.new(@docker_command)
          @command.stream

          if @command.success?
            # Open directly browser with new report
            stdout.puts "Opening Report open ./sitespeed_result/#{@folder_name}/index.html"
            Shellout.new("open ./sitespeed-result/#{@folder_name}/index.html").run
          end
        end
      end

      private

      attr_reader :stdout, :stderr
    end
  end
end
