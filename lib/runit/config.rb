# frozen_string_literal: true

require 'erb'
require 'fileutils'

module Runit
  class Config
    attr_reader :gdk_root

    Service = Struct.new(:name, :command)

    # @deprecated we should move this to `GDK::Service` when cleaning up Procfile based services
    TERM_SIGNAL = {
      'webpack' => 'KILL'
    }.freeze

    # User read-write, group and global read-only
    PERMISSION_READONLY = 0o644
    # User read write and execute, group and global read and execute
    PERMISSION_EXECUTION = 0o755

    # @param [Pathname] gdk_root
    def initialize(gdk_root)
      @gdk_root = gdk_root
    end

    def log_dir
      gdk_root.join('log')
    end

    def services_dir
      gdk_root.join('services')
    end

    def sv_dir(service)
      gdk_root.join('sv', service.name)
    end

    def run_env
      @run_env ||= generate_run_env
    end

    def render(services: services_from_procfile)
      FileUtils.mkdir_p(services_dir)
      FileUtils.mkdir_p(log_dir)

      max_service_length = services.map { |svc| svc.name.size }.max

      services.each_with_index do |service, i|
        create_runit_service(service)
        create_runit_down(service)
        create_runit_control_t(service)
        create_runit_log_service(service)
        create_runit_log_config(service, max_service_length, i)
        enable_runit_service(service)
      end

      FileUtils.rm(stale_service_links(services))
    end

    def stale_service_links(services)
      service_names = services.map(&:name)
      dir_matcher = %w[. ..]

      stale_entries = Dir.entries(services_dir).reject do |svc|
        service_names.include?(svc) || dir_matcher.include?(svc)
      end

      stale_entries.map do |entry|
        path = services_dir.join(entry)
        next unless File.symlink?(path)

        path
      end.compact
    end

    private

    # @deprecated should be removed when Procfile based services is not supported anymore
    def procfile_path
      @procfile_path ||= gdk_root.join('Procfile')
    end

    def generate_run_env
      render_template('runit/run_env.sh.erb')
    end

    # Load a list of services from Procfile
    #
    # @deprecated This will be removed when all services have been converted to GDK::Services
    def services_from_procfile
      abort 'fatal: need Procfile to continue, make it with `make Procfile`?' unless procfile_path.exist?

      procfile_path.readlines.map do |line|
        line.chomp!
        next if line.start_with?('#')

        name, command = line.split(': ', 2)
        next unless name && command

        delete_exec_prefix!(name, command)

        Service.new(name, command)
      end.compact
    end

    # @deprecated should be removed when Procfile based services is not supported anymore
    def delete_exec_prefix!(service, command)
      exec_prefix = 'exec '
      abort "fatal: Procfile command for service #{service} does not start with 'exec'" unless command.start_with?(exec_prefix)

      command.delete_prefix!(exec_prefix)
    end

    # Create runit `run` executable
    def create_runit_service(service)
      run = render_template('runit/run.sh.erb',
                            gdk_root: gdk_root,
                            run_env: run_env,
                            service: service)

      run_path = sv_dir(service).join('run')
      write_file(run_path, run, PERMISSION_EXECUTION)
    end

    # Create runit `down` file so that `runsvdir` won't boot this service
    # until you request it with `gdk start`
    #
    # @param [GDK::Service::Base] service
    def create_runit_down(service)
      write_file(sv_dir(service).join('down'), '', PERMISSION_READONLY)
    end

    # Create runit `control/t` executable
    #
    # @param [GDK::Service::Base] service
    def create_runit_control_t(service)
      term_signal = TERM_SIGNAL.fetch(service.name, 'TERM')
      pid_path = sv_dir(service).join('supervise/pid')

      control_t = render_template('runit/control/t.rb.erb',
                                  pid_path: pid_path,
                                  term_signal: term_signal)

      control_t_path = sv_dir(service).join('control/t')
      write_file(control_t_path, control_t, PERMISSION_EXECUTION)
    end

    # Create runit `log/run` executable
    #
    # @param [GDK::Service::Base] service
    def create_runit_log_service(service)
      service_log_dir = log_dir.join(service.name)
      FileUtils.mkdir_p(service_log_dir)

      log_run = render_template('runit/log/run.sh.erb', service_log_dir: service_log_dir)

      log_run_path = sv_dir(service).join('log/run')
      write_file(log_run_path, log_run, PERMISSION_EXECUTION)
    end

    # Create runit `log/:service:/config` file
    #
    # @param [GDK::Service::Base] service
    # @param [Integer] max_service_length
    # @param [Integer] index
    def create_runit_log_config(service, max_service_length, index)
      log_prefix = GDK::Output.ansi(GDK::Output.color(index))
      log_label = format("%-#{max_service_length}s : ", service.name)
      reset_color = GDK::Output.reset_color

      log_config = render_template('runit/log/config.erb',
                                   log_prefix: log_prefix,
                                   log_label: log_label,
                                   reset_color: reset_color,
                                   service: service)

      log_config_path = log_dir.join(service.name, 'config')
      write_file(log_config_path, log_config, PERMISSION_READONLY)
    end

    def enable_runit_service(service)
      # If the user removes this symlink, runit will stop managing this service.
      FileUtils.ln_sf(sv_dir(service), services_dir.join(service.name))
    end

    # Return UNIX termination signal for given service
    #
    # @param [GDK::Service::Base] service
    # @return [String] UNIX termination signal
    def term_signal(service)
      TERM_SIGNAL.fetch(service.name, 'TERM')
    end

    # Write content to a given file with specified permissions
    #
    # @param [String] path of the file
    # @param [String] content that will be written to the file
    # @param [Integer] permissions in chmod octal notation (ex: 0o755)
    def write_file(path, content, permissions)
      FileUtils.mkdir_p(File.dirname(path))

      File.open(path, 'w') { |f| f.write(content) }
      File.chmod(permissions, path)
    end

    # Render a template to string with optional injected local variables
    #
    # @param [String] template_path partial path starting from the template root folder
    # @param [Hash] locals any local variable that needs to be exposed in the template
    # @return [String] rendered content
    def render_template(template_path, **locals)
      template_fullpath = GDK.template_root.join(template_path)
      raise ArgumentError, "file not found in: #{template_path}" unless File.exist?(template_fullpath)

      template = File.read(template_fullpath)

      erb = ERB.new(template)
      erb.location = template_fullpath.to_s # define the file location so errors can point to the right file
      erb.result_with_hash(locals)
    end
  end
end
