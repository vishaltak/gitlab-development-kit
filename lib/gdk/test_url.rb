# frozen_string_literal: true

module GDK
  class TestURL
    MAX_ATTEMPTS = 90
    SLEEP_BETWEEN_ATTEMPTS = 3
    OPEN_TIMEOUT = 60
    READ_TIMEOUT = 60

    UrlAppearsInvalid = Class.new(StandardError)

    def self.default_url
      "#{GDK.config.__uri}/users/sign_in"
    end

    def initialize(url = self.class.default_url, max_attempts: MAX_ATTEMPTS, sleep_between_attempts: SLEEP_BETWEEN_ATTEMPTS, read_timeout: READ_TIMEOUT, open_timeout: OPEN_TIMEOUT)
      raise UrlAppearsInvalid unless URI::DEFAULT_PARSER.make_regexp.match?(url)

      @uri = URI.parse(url)
      @max_attempts = max_attempts
      @sleep_between_attempts = sleep_between_attempts
      @read_timeout = read_timeout
      @open_timeout = open_timeout
    end

    def wait(verbose: false)
      @start_time = Time.now

      GDK::Output.puts(GDK::Output.notice_format("Waiting until #{uri} is ready.."))

      if check_url(verbose: verbose)
        GDK::Output.notice("#{uri} is up (#{http_helper.last_response_reason}). Took #{duration} second(s).")
        true
      else
        GDK::Output.notice("#{uri} does not appear to be up. Waited #{duration} second(s).")
        false
      end
    end

    def check_url(override_max_attempts: max_attempts, verbose: false, silent: false)
      result = false
      display_output = verbose && !silent

      1.upto(override_max_attempts) do |i|
        GDK::Output.puts("\n> Testing attempt ##{i}..") if display_output

        if http_helper.head_up?
          GDK::Output.puts("#{http_helper.last_response_reason}\n") if display_output
          GDK::Output.puts unless silent
          result = true
          break
        end

        if display_output
          GDK::Output.puts(http_helper.last_response_reason)
        elsif !silent
          GDK::Output.print('.')
        end

        sleep(sleep_between_attempts)
      end

      result
    end

    def check_url_oneshot(verbose: false, silent: true)
      check_url(override_max_attempts: 1, verbose: verbose, silent: silent)
    end

    private

    attr_reader :uri, :start_time, :sleep_between_attempts, :max_attempts, :read_timeout, :open_timeout

    def duration
      (Time.now - start_time).round(2)
    end

    def http_helper
      @http_helper ||= GDK::HTTPHelper.new(uri, read_timeout: read_timeout, open_timeout: open_timeout, cache_response: false)
    end
  end
end
