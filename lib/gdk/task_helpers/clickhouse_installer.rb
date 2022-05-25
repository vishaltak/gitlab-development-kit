# frozen_string_literal: true

require 'tmpdir'

module GDK
  module TaskHelpers
    # Handles ClickHouse binary retrieval and installation for Linux and MacOS
    class ClickhouseInstaller
      INSTALL_VERSION = '22.5.1.1' # Git Tag: v22.5.1.2079-stable

      LINUX_URL = 'https://packages.clickhouse.com/tgz/stable/clickhouse-common-static-22.5.1.2079-amd64.tgz'
      MACOS_INTEL_URL = 'https://s3.amazonaws.com/clickhouse-builds/37289/36b4ed19c54aeba59ff842499980c2d38ecda212/binary_darwin/clickhouse'
      MACOS_ARM64_URL = 'https://s3.amazonaws.com/clickhouse-builds/37289/36b4ed19c54aeba59ff842499980c2d38ecda212/binary_darwin_aarch64/clickhouse'

      PERMISSION_EXECUTION = 0o755

      # Retrieve compressed tgz file and extract clickhouse binary for Linux 64bits
      #
      # @return [Boolean] whether installation was successful
      def fetch_linux64
        Dir.mktmpdir('clickhouse') do |dir|
          compressed_file = File.join(dir, 'clickhouse.tgz')

          unless fetch(LINUX_URL, compressed_file)
            GDK::Output.error('Failed to download ClickHouse x86_64 for Linux')
            GDK::Output.info("Download URL: #{LINUX_URL}")

            next false
          end

          unless extract_binary_from_tgz!(compressed_file)
            GDK::Output.puts
            GDK::Output.error('Failed to extract ClickHouse x86_64 for Linux from compressed file')

            next false
          end

          GDK::Output.puts
          GDK::Output.success('Installed ClickHouse for Linux x86_64')

          true
        end
      end

      # Retrieve pre-built MacOS binary for Intel processor
      #
      # @return [Boolean] whether installation was successful
      def fetch_macos_intel
        Dir.mktmpdir('clickhouse') do |dir|
          compiled_binary = File.join(dir, 'clickhouse')

          unless fetch(MACOS_INTEL_URL, compiled_binary)
            GDK::Output.puts
            GDK::Output.error('Failed to download ClickHouse for MacOS with Intel processor')
            GDK::Output.info("Download URL: #{MACOS_INTEL_URL}")

            next false
          end

          next false unless install_binary(compiled_binary)

          GDK::Output.puts
          GDK::Output.success('Installed ClickHouse for MacOS with Intel processor')

          ensure_gdk_config!

          true
        end
      end

      # Retrieve pre-built MacOS binary for Apple Silicon based processor
      #
      # @return [Boolean] whether installation was successful
      def fetch_macos_apple_silicon
        Dir.mktmpdir('clickhouse') do |dir|
          compiled_binary = File.join(dir, 'clickhouse')

          unless fetch(MACOS_ARM64_URL, compiled_binary)
            GDK::Output.puts
            GDK::Output.error('Failed to download ClickHouse for MacOS with an Apple Silicon processor')
            GDK::Output.info("Download URL: #{MACOS_ARM64_URL}")

            next false
          end

          next false unless install_binary(compiled_binary)

          GDK::Output.puts
          GDK::Output.success('Installed ClickHouse for MacOS with an Apple Silicon processor')

          ensure_gdk_config!

          true
        end
      end

      private

      def fetch(url, filename)
        command = %W[curl -C - -L --fail #{url} -o #{filename}]

        shellout(command)
      end

      def extract_binary_from_tgz!(source)
        ensure_install_dir_exist!

        target_path = File.dirname(install_path)
        command = %W[tar xzf #{source} --strip-components=3 -C #{target_path}]
        command << '--wildcards' if GDK::Machine.linux?
        command << '*/usr/bin/clickhouse'

        shellout(command)
      end

      def install_binary(source)
        ensure_install_dir_exist!

        FileUtils.mv(source, install_path)
        FileUtils.chmod(PERMISSION_EXECUTION, install_path)
      rescue Errno::EPERM, Errno::ENOENT
        GDK::Output.puts
        GDK::Output.error("Failed to install ClickHouse at: #{install_path}")

        false
      end

      def ensure_install_dir_exist!
        FileUtils.mkdir_p(File.dirname(install_path))
      rescue SystemCallError
        false
      end

      def install_path
        GDK.config.clickhouse.dir.join('clickhouse')
      end

      def shellout(command)
        sh = Shellout.new(command, chdir: GDK.root)
        sh.stream
        sh.success?
      rescue StandardError => e
        GDK::Output.puts
        GDK::Output.puts(e.message, stderr: true)

        false
      end

      # Ensure gdk.yml is pointing to the installed clickhouse
      #
      # If clickhouse.bin was previously set to something else that does not
      # exist anymore, when installing clickhouse we need to update the location
      # to point to the new one
      def ensure_gdk_config!
        return if GDK.config.clickhouse.bin == install_path

        command = %W[bin/gdk config set clickhouse.bin #{install_path}]
        shellout(command)
      end
    end
  end
end
