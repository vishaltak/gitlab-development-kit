# frozen_string_literal: true

$LOAD_PATH.unshift('.')
require 'pp'
require 'lib/helpers/config'
require 'lib/helpers/dependencies_finder'
require 'lib/helpers/output_helpers'

task :gdk_config do
  pp Helpers::Config.instance.config_data
end

task :bundler do
  Helpers::DependenciesFinder.ensure_bundler_available!
end

task :yarn do
  Helpers::DependenciesFinder.require_yarn_available!
end

namespace :gitlab do
  desc 'Install GitLab'
  task :setup do
    Helpers::DependenciesFinder.check_ruby_version!('2.5.0')

    # Load GDK config
    gdk_config = Helpers::Config.instance.config_data

    # Clone GitLab repository
    Helpers::Git.clone(gdk_config[:repositories][:gitlab], 'gitlab')

    # Build GitLab config files
    Rake::Task['gitlab:config'].invoke

    # Check if bundler is available otherwise install it
    Rake::Task['bundler'].invoke

    # Run bundler
    Rake::Task['gitlab:bundle_install'].invoke

    # Check if yarn is available otherwise install it
    Rake::Task['yarn'].invoke

    # Run yarn
    Rake::Task['gitlab:yarn_install'].invoke


    dot_gettext
  end

  task :config do
    system('make gitlab-config')
  end

  task :bundle_install do
    if Helpers::DependenciesFinder.mysql_present?
      system('bundle install --jobs 4 --without production --with mysql')
    else
      system('bundle install --jobs 4 --without production --without mysql')
    end
  end
end

namespace :alternative do
  require 'lib/gdk'
  require 'rake/clean'
  CLOBBER.include 'gdk.example.yml', 'Procfile', 'nginx/conf/nginx.conf'

  def config
    @config ||= GDK::Config.new
  end

  desc 'Dump the configured settings'
  task 'dump_config' do
    GDK::Config.new.dump!(STDOUT)
  end

  desc 'Generate an example config file with all the defaults'
  file 'gdk.example.yml' => 'clobber:gdk.example.yml' do |t|
    File.open(t.name, File::CREAT|File::TRUNC|File::WRONLY) do |file|
      config = Class.new(GDK::Config)
      config.define_method(:gdk_root) { '/home/git/gdk' }
      config.define_method(:username) { 'git' }
      config.define_method(:read!) { |_| nil }

      config.new(yaml: {}).dump!(file)
    end
  end

  task 'clobber:gdk.example.yml' do |t|
    Rake::Cleaner.cleanup_files([t.name])
  end

  desc 'Generate Procfile for Foreman'
  file 'Procfile' => ['Procfile.erb', GDK::Config::FILE] do |t|
    GDK::ErbRenderer.new(t.source, t.name).safe_render!
  end

  desc 'Generate nginx configuration'
  file 'nginx/conf/nginx.conf' => ['nginx/conf/nginx.conf.erb', GDK::Config::FILE] do |t|
    GDK::ErbRenderer.new(t.source, t.name).safe_render!
  end
end
