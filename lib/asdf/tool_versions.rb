# frozen_string_literal: true

require 'pathname'

module Asdf
  class ToolVersions
    def default_tool_version_for(tool)
      tool_versions[tool].default_tool_version
    end

    def default_version_for(tool)
      default_tool_version_for(tool).version
    end

    def unnecessary_software_to_uninstall?
      work_to_do?(output: false)
    end

    def uninstall_unnecessary_software!(prompt: true)
      return true unless work_to_do?

      if prompt
        inform
        return true unless confirm?
      end

      failed_to_uninstall = {}

      unnecessary_installed_versions_of_software.each do |name, versions|
        GDK::Output.print "Uninstalling #{name} "

        versions.each_with_index do |(version, tool_version), i|
          GDK::Output.print ', ' if i.positive?
          GDK::Output.print version

          begin
            tool_version.uninstall!
          rescue ToolVersion::UninstallFailedError
            failed_to_uninstall[name] ||= []
            failed_to_uninstall[name] << version
          end
        end

        icon = if failed_to_uninstall.empty?
                 :success
               elsif failed_to_uninstall.count == versions.count
                 :error
               else
                 :warning
               end

        GDK::Output.puts(" #{GDK::Output.icon(icon)}")
      end

      return true if failed_to_uninstall.empty?

      GDK::Output.puts(stderr: true)
      GDK::Output.warn("Failed to uninstall the following:\n\n")
      failed_to_uninstall.each do |name, versions|
        GDK::Output.puts("#{name} #{versions.join(', ')}")
      end

      false
    end

    def unnecessary_installed_versions_of_software
      installed_versions_of_wanted_software.each_with_object({}) do |(name, versions), unncessary_software|
        versions.each do |version, tool_version|
          next if wanted_software[name][version]

          unncessary_software[name] ||= {}
          unncessary_software[name][version] = tool_version
        end
      end
    end

    private

    def config
      @config ||= GDK.config
    end

    def asdf_opt_out?
      config.asdf.opt_out?
    end

    def inform
      GDK::Output.warn('About to uninstall the following asdf software:')
      GDK::Output.puts(stderr: true)

      unnecessary_installed_versions_of_software.each do |name, versions|
        GDK::Output.puts("#{name} #{versions.keys.join(', ')}")
      end

      GDK::Output.puts(stderr: true)
    end

    def work_to_do?(output: true)
      if !asdf_data_installs_dir.exist?
        GDK::Output.info("Skipping because '#{asdf_data_installs_dir}' does not exist.") if output
        return false
      elsif asdf_opt_out?
        GDK::Output.info('Skipping because asdf.opt_out is set to true.') if output
        return false
      elsif unnecessary_installed_versions_of_software.empty?
        GDK::Output.info('No unnecessary asdf software to uninstall.') if output
        return false
      end

      true
    end

    def confirm?
      return true if ENV.fetch('GDK_ASDF_UNINSTALL_UNNECESSARY_SOFTWARE_CONFIRM', 'false') == 'true' || !GDK::Output.interactive?

      GDK::Output.prompt('Are you sure? [y/N]').match?(/\Ay(?:es)*\z/i)
    end

    def raw_tool_versions_lines
      GDK.root.join('.tool-versions').readlines
    end

    def tool_versions
      @tool_versions ||= raw_tool_versions_lines.each_with_object({}) do |line, all|
        match = line.chomp.match(/\A(?<name>\w+) (?<versions>[\d. ]+)\z/)
        all[match[:name]] = Tool.new(match[:name], match[:versions].split(' ')) if match
      end
    end

    def wanted_software
      tool_versions.transform_values(&:tool_versions)
    end

    def asdf_data_dir
      @asdf_data_dir ||= Pathname.new(ENV.fetch('ASDF_DATA_DIR', File.join(ENV['HOME'], '.asdf')))
    end

    def asdf_data_installs_dir
      @asdf_data_installs_dir ||= asdf_data_dir.join('installs')
    end

    def asdf_install_dirs_for(name)
      asdf_data_installs_dir.join(name).glob('*')
    end

    def installed_versions_of_wanted_software
      wanted_software.each_with_object({}) do |(name, _), installed_software|
        asdf_install_dirs_for(name).each do |dir|
          version = dir.basename.to_s
          installed_software[name] ||= {}
          installed_software[name][version] = ToolVersion.new(name, version)
        end
      end
    end
  end
end
