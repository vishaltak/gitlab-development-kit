# frozen_string_literal: true

require 'simplecov-cobertura'

SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
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

def stub_gdk_yaml(yaml)
  allow(GDK).to receive(:config) { GDK::Config.new(yaml: yaml) }
end

def stub_pg_bindir
  fake_io = double('IO', read: '/usr/local/bin')
  allow(IO).to receive(:popen).and_call_original
  allow(IO).to receive(:popen).with(%w[support/pg_bindir], any_args).and_yield(fake_io)
end

def stub_tty(state)
  allow(STDOUT).to receive(:isatty).and_return(state)
end

def stub_no_color_env(res)
  stub_tty(true)

  # res needs to be of type String as we're simulating what's coming from
  # the shell command line.
  allow(ENV).to receive(:fetch).and_call_original
  allow(ENV).to receive(:fetch).with('NO_COLOR', '').and_return(res)
end
