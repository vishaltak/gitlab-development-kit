# frozen_string_literal: true

module GDK
  # Provides information about the machine
  module Machine
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
