# frozen_string_literal: true

require 'erb'
require 'fileutils'

module Runit
  class Config
    attr_reader :gdk_root

    Service = Struct.new(:name, :command)

    TERM_SIGNAL = {
      'webpack' => 'KILL'
    }.freeze

    def initialize(gdk_root)
      @gdk_root = gdk_root
    end

    def log_dir
      File.join(gdk_root, 'log')
    end

    def services_dir
      File.join(gdk_root, 'services')
    end

    def sv_dir
      File.join(gdk_root, 'sv')
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
        create_runit_control_t(service)
        create_runit_log_service(service, max_service_length, i)
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
        path = File.join(services_dir, entry)
        next unless File.symlink?(path)

        path
      end.compact
    end

    private

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

    def delete_exec_prefix!(service, command)
      exec_prefix = 'exec '
      abort "fatal: Procfile command for service #{service} does not start with 'exec'" unless command.start_with?(exec_prefix)

      command.delete_prefix!(exec_prefix)
    end

    def create_runit_service(service)
      run = render_template('runit/run.sh.erb',
                            gdk_root: gdk_root,
                            run_env: run_env,
                            service: service)

      run_path = File.join(dir(service), 'run')
      write_file(run_path, run, 0o755)

      # Create a 'down' file so that runsvdir won't boot this service until
      # you request it with `sv start`.
      write_file(File.join(dir(service), 'down'), '', 0o644)
    end

    def create_runit_control_t(service)
      term_signal = TERM_SIGNAL.fetch(service.name, 'TERM')
      pid_path = File.join(dir(service), 'supervise/pid')

      control_t = render_template('runit/control/t.rb.erb',
                                  pid_path: pid_path,
                                  term_signal: term_signal)

      control_t_path = File.join(dir(service), 'control/t')
      write_file(control_t_path, control_t, 0o755)
    end

    def create_runit_log_service(service, max_service_length, index)
      # runit log/run
      #

      service_log_dir = File.join(log_dir, service.name)
      FileUtils.mkdir_p(service_log_dir)

      log_run = render_template('runit/log/run.sh.erb', service_log_dir: service_log_dir)

      log_run_path = File.join(dir(service), 'log/run')
      write_file(log_run_path, log_run, 0o755)

      # runit config
      #

      log_prefix = GDK::Output.ansi(GDK::Output.color(index))
      log_label = format("%-#{max_service_length}s : ", service.name)
      reset_color = GDK::Output.reset_color

      log_config = render_template('runit/config.erb',
                                   log_prefix: log_prefix,
                                   log_label: log_label,
                                   reset_color: reset_color,
                                   service: service)

      log_config_path = File.join(service_log_dir, 'config')
      write_file(log_config_path, log_config, 0o644)
    end

    def enable_runit_service(service)
      # If the user removes this symlink, runit will stop managing this service.
      FileUtils.ln_sf(dir(service), File.join(services_dir, service.name))
    end

    def dir(service)
      File.join(sv_dir, service.name)
    end

    def write_file(path, content, perm)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') { |f| f.write(content) }
      File.chmod(perm, path)
    end

    def render_template(template_path, **args)
      template_fullpath = GDK.template_root.join(template_path)
      raise ArgumentError, "file not found in: #{template_path}" unless File.exist?(template_fullpath)

      template = File.read(template_fullpath)

      erb = ERB.new(template)
      # define the file location so errors can point to the right file
      erb.location = template_fullpath.to_s
      erb.result_with_hash(args)
    end
  end
end
