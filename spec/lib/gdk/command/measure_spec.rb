# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Command::Measure do
  let(:urls) { nil }
  let(:urls_default) { ['/explore'] }

  let(:docker_running) { nil }

  subject { described_class.new(urls) }

  before do
    stub_tty(false)
  end

  describe '#run' do
    before do
      stub_docker_check(is_running: docker_running)
    end

    context 'when an empty URL array is provided' do
      let(:urls) { [] }

      it 'aborts' do
        expected_error = 'ERROR: Please add URL(s) as an argument (e.g. http://localhost:3000/explore, /explore or https://gitlab.com/explore)'

        expect { subject.run }.to raise_error(expected_error).and output("#{expected_error}\n").to_stderr
      end
    end

    context "when Docker isn't installed or running " do
      let(:urls) { urls_default }
      let(:docker_running) { false }

      it 'aborts' do
        expected_error = 'ERROR: Docker is not installed or running!'

        expect { subject.run }.to raise_error(expected_error).and output("#{expected_error}\n").to_stderr
      end
    end

    context "when GDK isn't running or ready" do
      let(:urls) { urls_default }
      let(:docker_running) { true }

      context 'when GDK is not running' do
        it 'aborts' do
          expected_error = 'ERROR: GDK is not running locally on http://127.0.0.1:3000!'

          expect { subject.run }.to raise_error(expected_error).and output("#{expected_error}\n").to_stderr
        end
      end

      context 'when GDK is not ready' do
        it 'aborts' do
          stub_gdk_check(is_running: false)

          expected_error = 'ERROR: GDK is not running locally on http://127.0.0.1:3000!'

          expect { subject.run }.to raise_error(expected_error).and output("#{expected_error}\n").to_stderr
        end
      end
    end

    context 'when GDK is running' do
      let(:urls) { urls_default }
      let(:docker_running) { true }
      let(:branch_name) { 'some-branch-name' }

      before do
        stub_gdk_check(is_running: true)
        stub_git_rev_parse(branch_name: branch_name)
      end

      it 'runs sitespeed via Docker', :hide_stdout do
        freeze_time do
          current_time_formatted = Time.now.strftime('%F-%H-%M-%S')

          shellout_docker_run_double = double('Shellout', stream: '')
          allow(Shellout).to receive(:new).with(%[docker run --cap-add=NET_ADMIN --shm-size 2g --rm -v "$(pwd):/sitespeed.io" sitespeedio/sitespeed.io:15.9.0 -b chrome -n 4 -c cable --cookie perf_bar_enabled=false --outputFolder sitespeed-result/some-branch-name_#{current_time_formatted} http://host.docker.internal:3000/explore]).and_return(shellout_docker_run_double)

          shellout_open_double = double('Shellout', run: true)
          expect(Shellout).to receive(:new).with("open ./sitespeed-result/#{branch_name}_#{current_time_formatted}/index.html").and_return(shellout_open_double)

          subject.run
        end
      end
    end
  end

  def stub_git_rev_parse(branch_name:)
    shellout_double = instance_double(Shellout, run: branch_name)
    allow(Shellout).to receive(:new).with('git rev-parse --abbrev-ref HEAD', chdir: GDK.config.gitlab.dir).and_return(shellout_double)
  end

  def stub_docker_check(is_running:)
    shellout_double = instance_double(Shellout, run: true, success?: is_running)
    allow(Shellout).to receive(:new).with('docker info').and_return(shellout_double)
  end

  def stub_gdk_check(is_running:)
    http_helper_double = instance_double(GDK::HTTPHelper, up?: is_running)
    allow(GDK::HTTPHelper).to receive(:new).with(GDK.config.__uri).and_return(http_helper_double)
  end
end
