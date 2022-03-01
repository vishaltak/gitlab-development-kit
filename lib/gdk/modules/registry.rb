# frozen_string_literal: true

require 'fileutils'

module GDK
  module Modules
    class Registry < Base
      def setup
        config.storage_path.mkpath
        generate_file_if_not_exist(config.config_yml, 'registry/config.yml', 'config.rake')

        return if config.localhost_key_path.exist?

        Shellout.new(%(#{openssl_bin_path} req -new -subj "/CN=#{hostname}/" -x509 -days 365 -newkey rsa:2048 -nodes -keyout "#{config.localhost_key_path}" -out "#{config.localhost_crt_path}" -addext "subjectAltName=DNS:#{config.host})).execute
        config.localhost_key_path.chmod(0o600)
      end

      def trust
        unless config.registry_host_key_path.exist?
          Shellout.new(%(#{openssl_bin_path} req -new -subj "/CN=#{config.host}/" -x509 -days 365 -newkey rsa:2048 -nodes -keyout "#{config.registry_host_key_path}" -out "#{config.registry_host_crt_path}" -addext "subjectAltName=DNS:#{config.host}")).execute
          config.registry_host_key_path.chmod(0o600)
        end

        config.__docker_certs_d_path.mkpath
        config.__docker_certs_ca_crt_path.delete if config.__docker_certs_ca_crt_path.exist?

        FileUtils.cp(config.registry_host_crt_path, config.__docker_certs_ca_crt_path)

        GDK::Output.success("Certificates have been copied to '#{config.__docker_certs_d_path}'")
        GDK::Output.info("Don't forget to restart Docker!")
      end

      private

      def config
        gdk_config.registry
      end

      def openssl_bin_path
        gdk_config.__openssl_bin_path
      end
    end
  end
end
