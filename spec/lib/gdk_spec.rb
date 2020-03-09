# frozen_string_literal: true

require 'spec_helper'

describe GDK do
  before do
    $gdk_root = 'root'
    allow(GDK).to receive(:install_root_ok?).and_return(true)
  end

  def expect_exec(input, cmdline)
    expect(subject).to receive(:exec).with(*cmdline)

    ARGV.replace(input)
    subject.main
  end

  describe '.main' do
    describe 'psql' do
      it 'uses the development database by default' do
        expect_exec ['psql'],
                    ['psql', '-h', 'root/postgresql', '-p', '5432', '-d', 'gitlabhq_development', chdir: 'root']
      end

      it 'uses custom arguments if present' do
        expect_exec ['psql', '-w', '-d', 'gitlabhq_test'],
                    ['psql', '-h', 'root/postgresql', '-p', '5432', '-w', '-d', 'gitlabhq_test', chdir: 'root']
      end
    end
  end

  describe 'commands' do
    before do
      $gdk_root = fixture_path
      allow(GDK::Logo).to receive(:print)
    end

    shared_examples 'help command' do
      it 'prints the logo' do
        expect(GDK::Logo).to receive(:print)
        subject.main
      end

      it 'prints a message about usage' do
        expect { subject.main }.to output("Usage: gdk <command> [<args>]\n").to_stdout
      end
    end

    context 'with no argument supplied' do
      it_behaves_like 'help command'
    end

    context 'with the "help" argument supplied' do
      before do
        ARGV.replace(['help'])
      end

      it_behaves_like 'help command'
    end
  end
end
