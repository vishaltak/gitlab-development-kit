# frozen_string_literal: true

require 'time'

module GDK
  module Command
    class Measure
      def initialize(urls)
        @urls = urls
      end

      def run
        abort('Please add a URL as argument (e.g. http://localhost:3000/explore, /explore or https://gitlab.com/explore)') if urls.empty?
        abort('ERROR: Docker is not installed or running!') unless docker_running?

        # .. the reset of the logic here ..
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
          abort("ERROR: GDK is not running locally on #{GDK.config.__uri}!") if has_local_url? && !gdk_running?

          stdout.puts "Starting Sitespeed measurements for #{local_urls.join(', ')}"
          run_sitespeed

          # Open directly browser with new report
          stdout.puts "Opening Report open ./sitespeed_result/#{save_folder}/index.html"
          Shellout.new("open ./sitespeed-result/#{save_folder}/index.html").run
        end
      end

      private

      attr_reader :urls

      def gdk_running?
         %w[200 302].include?(Net::HTTP.get_response(GDK.config.__uri).code)
      end

      def docker_running?
        docker_check = Shellout.new('docker info')
        docker_check.run
        docker_check.success?
      end

      def report_folder_name
        @report_folder_name ||= begin
          folder_name = @has_local_url ? Shellout.new('git rev-parse --abbrev-ref HEAD', chdir: GDK.config.gitlab.dir).run : 'external'
          folder_name + "_#{Time.new.strftime('%F-%H-%M-%S')}"
        end
      end
    end
  end
end
