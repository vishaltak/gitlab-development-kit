# frozen_string_literal: true

require 'active_support/testing/time_helpers'
require 'simplecov-cobertura'

# rubocop:disable Layout/FirstArrayElementIndentation
SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::SimpleFormatter,
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::CoberturaFormatter
])
# rubocop:enable Layout/FirstArrayElementIndentation

SimpleCov.start

require_relative '../lib/gdk'

RSpec.configure do |config|
  config.before do |example|
    allow(GDK::Output).to receive(:puts) if example.metadata[:hide_stdout]

    # isolate configs for the testing environment
    allow(GDK).to receive(:root) { Pathname.new(temp_path) }
    stub_const('GDK::Config::GDK_ROOT', '/home/git/gdk')
    stub_const('GDK::Config::FILE', 'gdk.example.yml')
  end

  config.disable_monkey_patching
  config.include ActiveSupport::Testing::TimeHelpers
end

def spec_path
  Pathname.new(__dir__).expand_path
end

def fixture_path
  spec_path.join('fixtures')
end

def temp_path
  spec_path.parent.join('tmp')
end

def stub_env_lookups
  allow(ENV).to receive(:fetch).and_call_original
  allow(ENV).to receive(:[]).and_call_original
end

def stub_env(var, value)
  allow(ENV).to receive(:fetch).with(var, '').and_return(value)
  allow(ENV).to receive(:[]).with(var).and_return(value)
end

def stub_gdk_yaml(yaml)
  allow(GDK).to receive(:config) { GDK::Config.new(yaml: yaml) }
end

def stub_pg_bindir
  fake_io = double('IO', read: '/usr/local/bin')
  allow(IO).to receive(:popen).and_call_original
  allow(IO).to receive(:popen).with(%w[support/pg_bindir], any_args).and_yield(fake_io)
end

def stub_tty(state)
  allow($stdout).to receive(:isatty).and_return(state)
end

def stub_no_color_env(res)
  stub_tty(true)

  # res needs to be of type String as we're simulating what's coming from
  # the shell command line.
  stub_env('NO_COLOR', res)
end

def stub_gdk_yml_backup_and_save(now, expected_content)
  file_name = 'gdk.example.yml'
  backup_file_name = File.join(GDK.backup_dir, "#{file_name}.#{now.strftime('%Y%m%d%H%M%S')}")

  expect(FileUtils).to receive(:mkdir_p).with(GDK.backup_dir)
  expect(FileUtils).to receive(:cp).with(file_name, backup_file_name)

  expect(GDK::Output).to receive(:warn).with("Your '#{file_name}' is about to be re-written.")
  expect(GDK::Output).to receive(:info).with("A backup will be saved at '#{backup_file_name}'.")

  expect(File).to receive(:write).with(file_name, expected_content)
end
