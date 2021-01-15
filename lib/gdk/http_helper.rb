# frozen_string_literal: true

require 'net/http'

module GDK
  class HTTPHelper
    def initialize(uri, read_timeout: 5, open_timeout: 5)
      raise 'uri needs to be an instance of URI' unless uri.is_a?(URI)

      @uri = uri
      @read_timeout = read_timeout
      @open_timeout = open_timeout
    end

    def up?(codes_to_consider_up: %w[200 301 302])
      return false unless response

      codes_to_consider_up.include?(response.code)
    end

    private

    attr_reader :uri, :read_timeout, :open_timeout

    def response
      @response ||= begin
        http_client.start do |http|
          path = uri.path.empty? ? '/' : uri.path
          http.get(path)
        end
      end
    rescue Errno::ECONNREFUSED
      false
    end

    def http_client
      Net::HTTP.new(uri.host, uri.port).tap do |client|
        client.read_timeout = read_timeout
        client.open_timeout = open_timeout
        client.use_ssl = uri.port == 443
      end
    end
  end
end
