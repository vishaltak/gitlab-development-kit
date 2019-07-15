# frozen_string_literal: true

$LOAD_PATH.unshift('.')

require 'pp'
require 'lib/helpers/config'
require 'lib/helpers/dependencies_finder'
require 'lib/helpers/output_helpers'
require 'lib/helpers/git'

task :gdk_config do
  pp Helpers::Config.instance.config_data
end

namespace :gitlab do
  desc 'Install GitLab and its Ruby / Javascript dependencies'
  task setup: [:prerequisites, 'gitlab', :config, :install_dependencies, 'gitlab/.gettext']

  desc 'Build GitLab config files'
  task :config do
    system 'make gitlab-config'
  end

  desc 'Compile GitLab I18n'
  task :gettext_compile do
    system 'cd gitlab && bundle exec rake gettext:compile > gettext.log 2>&1'
    system 'git -C gitlab checkout locale/*/gitlab.po'
  end

  #
  # Private tasks (use as dependency only)
  #

  task :prerequisites do
    Helpers::DependenciesFinder.check_ruby_version!('2.6.3')
    Helpers::DependenciesFinder.ensure_bundler_available!('1.17.3')
    Helpers::DependenciesFinder.require_yarn_available!
  end

  multitask install_dependencies: [:bundle_install, 'gitlab/node_modules']

  task :bundle_install do
    next unless GDK::Dependencies.bundler_missing_dependencies?('gitlab')

    system 'bundle install --jobs 4 --without production', chdir: 'gitlab'
  end

  task :yarn_install do
    system 'yarn install --no-progress --pure-lockfile', chdir: 'gitlab'
  end
end

#
# Bootstrap tasks (only run when setting up for the first time)
#

directory 'gitlab' do |t|
  # Load GDK config
  gdk_config = Helpers::Config.instance.config_data

  Helpers::Git.clone_repo(gdk_config[:repositories][:gitlab], t.name)
end

directory 'gitlab/node_modules' do
  Rake::Task['gitlab:yarn_install']
end

file 'gitlab/.gettext' do |t|
  Rake::Task['gitlab:gettext_compile'].invoke

  `touch #{t.name}`
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
  File.open(t.name, File::CREAT | File::TRUNC | File::WRONLY) do |file|
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
