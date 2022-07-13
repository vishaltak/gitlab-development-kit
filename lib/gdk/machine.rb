# frozen_string_literal: true

module GDK
  # Provides information about the machine
  module Machine
    ARM64_VARIATIONS = %w[arm64 aarch64].freeze

    # Is the machine running Linux?
    #
    # @return [Boolean] whether we are in a Linux machine
    def self.linux?
      platform == 'linux'
    end

    # Is the machine running MacOS?
    #
    # @return [Boolean] whether we are in a MacOS machine
    def self.macos?
      platform == 'darwin'
    end

    # Is the machine running a supported OS?
    #
    # @return [Boolean] whether we are running a supported OS
    def self.supported?
      platform != 'unknown'
    end

    # Is the machine running on an ARM64 processor?
    #
    # @return [Boolean] whether current architecture is using ARM64 architecture
    def self.arm64?
      ARM64_VARIATIONS.any?(architecture)
    end

    # Is the machine running on an x86_64 processor?
    #
    # @return [Boolean] whether current CPU is using x86_64 architecture
    def self.x86_64?
      architecture == 'x86_64'
    end

    # The kernel type the machine is running on
    #
    # @return [String] darwin, linux, unknown
    def self.platform
      case RbConfig::CONFIG['host_os']
      when /darwin/i
        'darwin'
      when /linux/i
        'linux'
      else
        'unknown'
      end
    end

    # The CPU architecture of the machine
    #
    # @return [String] the cpu architecture
    def self.architecture
      RbConfig::CONFIG['target_cpu']
    end
  end
end
