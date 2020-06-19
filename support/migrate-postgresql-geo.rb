#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require_relative '../lib/gdk'

module Postgres
  module Errors
    attr_reader :error_namespace

    def valid?
      validate!
      errors.empty?
    end

    def print_errors
      return if errors.empty?

      errors.each do |error|
        puts "[#{error_namespace}] #{error}"
      end
    end

    def errors
      @errors ||= []
    end

    def validate!
      raise NotImplementedError
    end
  end

  class BinBundle
    include Errors

    attr_reader :bin_path

    def initialize(bin_path)
      @bin_path = bin_path
      @error_namespace = bin_path
    end

    def validate!
      unless Dir.exist?(bin_path)
        errors << 'Not a valid directory'

        return false
      end

      unless File.exist?(File.join(bin_path, 'psql'))
        errors << "Cannot find 'psql' binary in #{bin_path}"

        return false
      end

      true
    end
  end

  class Upgrader
    attr_reader :old_bundle, :new_bundle, :data_path

    def initialize(old_bundle:, new_bundle:, data_path:)
      @old_bundle = old_bundle
      @new_bundle = new_bundle
      @data_path = data_path
    end

    def execute
      pre_checks!

      unless postgres_can_be_upgraded?
        puts
        puts 'Migration aborted. See details above!'

        exit 1
      end

      sh('gdk', 'stop')

      # backup old data directory
      old_data = "#{data_path}.#{Time.now.to_i}"
      FileUtils.mv(data_path, old_data)

      # create new data directory and migrate
      sh(pg_path('initdb'), '--locale=C', '-E utf-8', data_path)
      sh(pg_path('pg_upgrade'), '-b', old_bundle.bin_path, '-B', new_bundle.bin_path, '-d', old_data, '-D', data_path)

      GDK.make('postgresql/geo/port')
    rescue Errno::EEXIST
      puts 'Destination already exist.'

      exit 1
    end

    private

    def postgres_can_be_upgraded?
      data_path_candidate = "#{data_path}-candidate-#{Time.now.to_i}"

      sh(pg_path('initdb'), '--locale=C', '-E utf-8', data_path_candidate, stream: false)
      sh(pg_path('pg_upgrade'), '-b', old_bundle.bin_path, '-B', new_bundle.bin_path, '-d', data_path, '-D', data_path_candidate, '-c')
    ensure
      FileUtils.remove_dir(data_path_candidate) if Dir.exist?(data_path_candidate)
    end

    def pre_checks!
      # check if bundles are valid
      return if old_bundle.valid? || new_bundle.valid?

      old_bundle.print_errors
      new_bundle.print_errors

      exit 1
    end

    def pg_path(binary)
      File.join(@new_bundle.bin_path, binary)
    end

    def sh(*args, stream: true)
      sh = Shellout.new(*args, chdir: GDK.root)

      if stream
        sh.stream
      else
        sh.run
      end

      sh.success?
    end
  end
end

unless ARGV.count == 2
  puts 'Usage:'
  puts "   #{__FILE__} <old-postgresql-bin-dir> <new-postgresql-bin-dir>"
  puts
  puts 'Example:'
  puts "   #{__FILE__} '/usr/local/opt/postgresql@11/bin' '/usr/local/opt/postgresql@12/bin'"

  exit 1
end

pg_old = Postgres::BinBundle.new(ARGV[0])
pg_new = Postgres::BinBundle.new(ARGV[1])

data_path = File.join(__dir__, 'postgresql-geo', 'data')

upgrader = Postgres::Upgrader.new(old_bundle: pg_old, new_bundle: pg_new, data_path: data_path)
upgrader.execute
