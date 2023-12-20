# frozen_string_literal: true

module GDK
  module Diagnostic
    class StaleServices < Base
      TITLE = 'Stale Services'

      def success?
        @success ||= ps_command_success? && stale_processes.empty?
      end

      def detail
        return if success?

        stale_services_detail
      end

      private

      StaleProcess = Struct.new(:pid, :service)

      def ps_command_success?
        # For this particular command, pgrep will return a 0 if there are matches
        # or 1 if there are no matches. We consider these exit codes a success and
        # any _other_ codes a failure.
        @ps_command_success ||= [0, 1].include?(ps_command.exit_code)
      end

      def ps_command
        @ps_command ||= Shellout.new(command).execute(display_output: false, display_error: false)
      end

      def command
        @command ||= %(pgrep -l -P 1 -f "runsv (#{service_names.join('|')})")
      end

      def service_names
        %w[
          elasticsearch
          geo-cursor
          gitaly
          gitlab-docs
          gitlab-k8s-agent
          gitlab-pages
          gitlab-ui
          gitlab-workhorse
          grafana
          jaeger
          mattermost
          minio
          nginx
          openldap
          postgresql
          postgresql-geo
          postgresql-replica
          praefect
          prometheus
          rails-background-jobs
          rails-web
          redis
          registry
          runner
          snowplow-micro
          spamcheck
          sshd
          tunnel_
          webpack
          sleep
        ]
      end

      def stale_processes
        @stale_processes ||=
          if ps_command_success?
            ps_command.read_stdout.split("\n").each_with_object([]) do |process, all|
              m = process.match(/^(?<pid>\d+) +runsv (?<service>.+)$/)
              next unless m

              all << StaleProcess.new(m[:pid], m[:service])
            end
          else
            []
          end
      end

      def stale_services_detail
        return if success?

        return "Unable to run '#{command}'." if stale_processes.empty?

        stale_services = stale_processes.map(&:service).join("\n")
        stale_pids = stale_processes.map(&:pid).join(' ')

        <<~MESSAGE
          The following GDK services appear to be stale:

          #{stale_services}

          You can try killing them by running 'gdk kill' or:

           kill #{stale_pids}
        MESSAGE
      end
    end
  end
end
