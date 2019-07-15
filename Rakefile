# frozen_string_literal: true

$LOAD_PATH.unshift('.')
Rake.add_rakelib 'lib/tasks'

require 'pp'
require 'lib/helpers/config'
require 'lib/helpers/dependencies_finder'
require 'lib/helpers/output_helpers'
require 'lib/helpers/git'

task :gdk_config do
  pp Helpers::Config.instance.config_data
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
