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
  Helpers::DependenciesFinder.ensure_bundler_available!('1.17.3')
end

task :yarn do
  Helpers::DependenciesFinder.require_yarn_available!
end

namespace :gitlab do
  desc 'Install GitLab'
  task :setup do
    Helpers::DependenciesFinder.check_ruby_version!('2.6.3')

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

    # Compile GitLab I18n
    Rake::Task['gitlab:gettext_compile']
  end

  task :config do
    system('make gitlab-config')
  end

  task :bundle_install do
    system('bundle install --jobs 4 --without production')
  end

  task :yarn_install do
    system('yarn install --pure-lockfile')
  end

  task :gettext_compile do
    system('cd gitlab && bundle exec rake gettext:compile > gettext.log 2>&1')
    system('git -C gitlab checkout locale/*/gitlab.po')
  end
end

# TODO: Cleanup below

require 'lib/gdk'

# Handles cleaning of generated files
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
