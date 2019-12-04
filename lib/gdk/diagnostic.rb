# frozen_string_literal: true

require 'stringio'

module GDK
  module Diagnostic
    def self.all
      self.constants.grep(/^Diagnose/).map do |const|
        self.const_get(const).new
      end
    end

    class Base
      TITLE = 'Diagnostic name'

      def initialize
        @success = false
      end

      def diagnose
        # Do stuff
      end

      def success?
        @success
      end

      def message
        <<~MESSAGE

          #{self.class::TITLE}
          #{'-' * 80}
          #{detail}
        MESSAGE
      end

      def detail
        ''
      end

    end

    class DiagnoseDependencies < Base
      TITLE = 'GDK Dependencies'

      def diagnose
        @checker = Dependencies::Checker.new
        @checker.check_all
        @success = @checker.error_messages.empty?
      end

      def detail
        <<~MESSAGE
          #{@checker.error_messages.join("\n")}
        MESSAGE
      end
    end

    class DiagnoseVersion < Base
      TITLE = 'GDK Version'

      def diagnose
        gdk_master = `git show-ref refs/remotes/origin/master -s --abbrev`
        head = `git rev-parse --short HEAD`
        @success = head == gdk_master
      end

      def detail
        <<~MESSAGE
          If you are not currently developing GDK, consider updating GDK with `gdk update`.
        MESSAGE
      end
    end

    class DiagnoseStatus < Base
      TITLE = 'GDK Status'

      def diagnose
        shell = Shellout.new('gdk status')
        shell.run
        status = shell.read_stdout

        @down_services = status.split("\n").select { |svc| svc.start_with?('down') }
        @success = @down_services.empty?
      end

      def detail
        <<~MESSAGE
          The following services are not running.
          #{@down_services.join("\n")}
        MESSAGE
      end
    end

    class DiagnosePendingMigrations < Base
      TITLE = 'Database Migrations'

      def diagnose
        shellout = Shellout.new(%W[bundle exec rails db:abort_if_pending_migrations], chdir: 'gitlab')
        shellout.run

        @success = shellout.success?
      end

      def detail
        <<~MESSAGE
          There are pending database migrations.
          To update your database, run `cd gitlab && bundle exec rails db:migrate`.
        MESSAGE
      end
    end

    class DiagnoseConfiguration < Base
      TITLE = 'GDK Configuration'

      def diagnose
        out = StringIO.new
        err = StringIO.new

        GDK::Command::DiffConfig.new.run(stdout: out, stderr: err)

        out.close
        err.close

        @config_diff = out.string
        @success = @config_diff.empty?
      end

      def detail
        <<~MESSAGE
          Please review the following diff or consider `gdk reconfigure`.

          #{@config_diff}
        MESSAGE
      end
    end
  end
end
