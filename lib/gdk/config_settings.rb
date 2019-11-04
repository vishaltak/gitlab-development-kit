# frozen_string_literal: true

require 'yaml'

module GDK
  class ConfigSettings
    SettingUndefined = Class.new(StandardError)

    attr_reader :parent, :yaml, :key, :invalid_configs

    def self.method_missing(name, *args, **opts, &blk)
      if opts[:type]
        expected_types[name] = opts[:type]
      end

      if !args.empty?
        define_method(name) do
          yaml.fetch(name.to_s, args.first)
        end
      elsif block_given?
        define_method(name) do
          # return the result of the block if it didn't take an argument
          # otherwise return an instance of the sub ConfigSettings
          return yaml.fetch(name.to_s, instance_eval(&blk)) if blk.arity.zero?

          subconfig!(name, &blk)
        end
      else
        super
      end
    end

    def self.expected_types
      @expected_types ||= Hash.new
    end

    def initialize(parent: nil, yaml: nil, key: nil)
      @parent = parent
      @key = key
      @yaml = yaml || load_yaml!
      @invalid_configs = {}
    end

    def dump!(file = nil)
      yaml = config_names.inject({}) do |hash, method|
        value = fetch(method)
        if value.is_a?(ConfigSettings)
          hash[method.to_s] = value.dump!
        elsif value.is_a?(Enumerable) && value.first.is_a?(ConfigSettings)
          hash[method.to_s] = value.map(&:dump!)
        else
          hash[method.to_s] = value
        end
        hash
      end

      file.puts(yaml.to_yaml) if file

      yaml
    end

    def dump_run_env!
      <<~RUN_ENV
        export host=#{hostname}
        export port=#{port}
        export relative_url_root=#{relative_url_root}
        export GITLAB_TRACING='opentracing://jaeger?http_endpoint=http%3A%2F%2Flocalhost%3A14268%2Fapi%2Ftraces&sampler=const&sampler_param=1'
        export GITLAB_TRACING_URL='http://localhost:16686/search?service={{ service }}&tags=%7B"correlation_id"%3A"{{ correlation_id }}"%7D'
      RUN_ENV
    end

    def env!(name)
      value = ENV[name]
      value&.empty? ? nil : value
    end

    def cmd!(cmd)
      # Passing an array to IO.popen guards against sh -c.
      # https://gitlab.com/gitlab-org/gitlab/blob/master/doc/development/shell_commands.md#bypass-the-shell-by-splitting-commands-into-separate-tokens
      raise ::ArgumentError.new('Command must be an array') unless cmd.is_a?(Array)

      IO.popen(cmd, &:read).chomp
    end

    def find_executable!(bin)
      result = cmd!(%W[which #{bin}])
      result.empty? ? nil : result
    end

    def read!(filename)
      sanitized_read!(filename)
    rescue Errno::ENOENT
      nil
    end

    def read_or_write!(filename, value)
      sanitized_read!(filename)
    rescue Errno::ENOENT
      File.write(filename, value)
      value
    end

    # Create an array of configs with self as parent
    #
    # @param count [Integer] the number of configs in the array
    def config_array!(count, &blk)
      count.times.map do |i|
        subconfig!(i, &blk)
      end
    end

    def fetch(key, *args)
      raise ::ArgumentError.new(%Q[Wrong number of arguments (#{args.count + 1} for 1..2)]) if args.count > 1

      return public_send(key) if respond_to?(key)

      raise SettingUndefined.new(%Q[Could not fetch the setting '#{key}' in '#{self.key || '<root>'}']) if args.empty?

      args.first
    end

    def [](key)
      fetch(key, nil)
    end

    def dig(*keys)
      keys = keys.first.to_s.split('.') if keys.one?

      value = fetch(keys.shift)

      return value if keys.empty?

      value.dig(*keys)
    end

    def root
      parent&.root || self
    end
    alias_method :config, :root

    def inspect
      "#<GDK::ConfigSettings key:#{key}>"
    end

    def to_s
      dump!.to_yaml
    end

    def validate
      config_names.each do |config_name|
        value = fetch(config_name)

        if value.is_a? ConfigSettings
          validate_subconfig(config_name, value)
        else
          validate_value(config_name, value)
        end
      end
    end

    def error_messages
      @invalid_configs.map do |name, type|
        "#{name} should be a #{type}"
      end
    end

    # Provide a shorter form for `config.setting.enabled` as `config.setting?`
    def method_missing(method_name, *args, &blk)
      enabled = enabled_value(method_name)

      return super if enabled.nil?

      enabled
    end

    def respond_to_missing?(method_name, include_private = false)
      !enabled_value(method_name).nil? || super
    end

    private

    def base_methods
      ConfigSettings.new.methods
    end

    def config_names
      (methods - base_methods).reject do |method|
        # If a config starts with a double underscore,
        # it's an internal config so don't include it
        method.to_s.start_with?('__')
      end.sort
    end

    def validate_subconfig(config_name, subconfig)
      subconfig.validate
      subconfig.invalid_configs.each do |subconfig_name, expected_type|
        @invalid_configs["#{config_name}.#{subconfig_name}"] = expected_type
      end
    end

    def validate_value(config_name, value)
      expected_type = self.class.expected_types[config_name]

      case expected_type
      when :integer
        unless value.is_a? Integer
          @invalid_configs[config_name.to_s] = expected_type
        end
      when :string
        unless value.is_a? String
          @invalid_configs[config_name.to_s] = expected_type
        end
      when :boolean
        unless value.is_a? TrueClass or value.is_a? FalseClass
          @invalid_configs[config_name.to_s] = expected_type
        end
      end
    end

    def enabled_value(method_name)
      chopped_name = method_name.to_s.chop.to_sym

      return nil unless method_name.to_s.end_with?('?')

      fetch(chopped_name, nil)&.fetch(:enabled, nil)
    end

    def subconfig!(name, &blk)
      sub = Class.new(ConfigSettings)
      blk.call(sub, name)
      sub.new(parent: self, yaml: yaml.fetch(name.to_s, {}), key: [key, name].compact.join('.'))
    end

    def load_yaml!
      return {} unless defined?(self.class::FILE) && File.exist?(self.class::FILE)

      YAML.load_file(self.class::FILE) || {}
    end

    def from_yaml(key, default: nil)
      yaml.has_key?(key) ? yaml[key] : default
    end

    def sanitized_read!(filename)
      sanitize_value(File.read(filename).chomp)
    end

    def sanitize_value(value)
      return true if value == "true"
      return false if value == "false"
      return value.to_i if value == value.to_i.to_s
      value
    end
  end
end
