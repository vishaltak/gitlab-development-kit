# frozen_string_literal: true

require 'gitlab-sdk'

autoload :FileUtils, 'fileutils'
autoload :Logger, 'logger'
autoload :Sentry, 'sentry-ruby'
autoload :SnowplowTracker, 'snowplow-tracker'

module GDK
  module Telemetry
    ANALYTICS_APP_ID = '35SLpKmD0ZB-K34dBAz9Tg'
    ANALYTICS_BASE_URL = 'https://collector.prod-1.gl-product-analytics.com'
    SENTRY_DSN = 'https://glet_1a56990d202783685f3708b129fde6c0@observe.gitlab.com:443/errortracking/api/v1/projects/48924931'

    def self.with_telemetry(command)
      return yield unless telemetry_enabled?

      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      result = yield

      duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

      send_telemetry(result, command, { duration: duration, platform: platform })

      result
    end

    def self.send_telemetry(success, command, payload = {})
      # This is tightly coupled to GDK commands and returns false when the system call exits with a non-zero status.
      status = success ? 'Finish' : 'Failed'

      client.identify(GDK.config.telemetry.username)
      client.track("#{status} #{command} #{ARGV}", payload)
    end

    def self.flush_events(async: false)
      client.flush_events(async: async)
    end

    def self.platform
      GDK.config.telemetry.platform
    end

    def self.client
      return @client if @client

      app_id = ENV.fetch('GITLAB_SDK_APP_ID', ANALYTICS_APP_ID)
      host = ENV.fetch('GITLAB_SDK_HOST', ANALYTICS_BASE_URL)

      SnowplowTracker::LOGGER.level = Logger::WARN
      @client = GitlabSDK::Client.new(app_id: app_id, host: host)
    end

    def self.init_sentry
      Sentry.init do |config|
        config.dsn = SENTRY_DSN
        config.breadcrumbs_logger = [:sentry_logger]
        config.traces_sample_rate = 1.0
        config.logger.level = Logger::WARN
      end
    end

    def self.capture_exception(message)
      return unless telemetry_enabled?

      if message.is_a?(Exception)
        exception = message
      else
        exception = StandardError.new(message)
        exception.set_backtrace(caller)
      end

      init_sentry
      Sentry.capture_exception(exception)
    end

    def self.telemetry_enabled?
      GDK.config.telemetry.enabled
    end

    def self.update_settings(username)
      enabled = true

      if username == '.'
        username = ''
        enabled = false
      end

      FileUtils.touch(GDK::Config::FILE)
      GDK.config.bury!('telemetry.enabled', enabled)
      GDK.config.bury!('telemetry.username', username)
      GDK.config.save_yaml!
    end
  end
end
