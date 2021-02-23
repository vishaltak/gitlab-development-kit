# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Command::Measure do
  let(:urls) { nil }
  let(:urls_default) { %w[/explore] }

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

      it 'aborts' do
        stub_gdk_check(is_running: false)

        expected_error = 'ERROR: GDK is not running locally on http://127.0.0.1:3000!'

        expect { subject.run }.to raise_error(expected_error).and output("#{expected_error}\n").to_stderr
      end
    end

    context 'when GDK is running' do
      let(:urls) { nil }
      let(:docker_running) { true }
      let(:branch_name) { 'some-branch-name' }
      let(:report_file_path) { nil }
      let!(:current_time_formatted) { Time.now.strftime('%F-%H-%M-%S') }

      before do
        stub_gdk_check(is_running: true)
        stub_git_rev_parse(branch_name: branch_name)
      end

      context 'when argument is a URL' do
        let(:urls) { urls_default }
        let(:report_file_path) { "sitespeed-result/#{branch_name}_#{current_time_formatted}" }

        it 'runs sitespeed via Docker for the given URL', :hide_stdout do
          freeze_time do
            shellout_docker_run_double = double('Shellout', stream: '')
            expect(Shellout).to receive(:new).with(%(docker run --cap-add=NET_ADMIN --shm-size 2g --rm -v "$(pwd):/sitespeed.io" sitespeedio/sitespeed.io:16.8.1 -b chrome -n 4 -c cable --cookie perf_bar_enabled=false --cpu --outputFolder #{report_file_path} http://host.docker.internal:3000/explore)).and_return(shellout_docker_run_double)

            shellout_open_double = double('Shellout', run: true)
            expect(Shellout).to receive(:new).with("open ./#{report_file_path}/index.html").and_return(shellout_open_double)

            subject.run
          end
        end
      end

      context 'when argument is predefined workflow' do
        let(:urls) { %w[repo_browser] }
        let(:report_file_path) { "sitespeed-result/external_#{current_time_formatted}" }

        it 'runs sitespeed via Docker for the given script', :hide_stdout do
          freeze_time do
            shellout_docker_run_double = double('Shellout', stream: '')
            expect(Shellout).to receive(:new).with(%(docker run --cap-add=NET_ADMIN --shm-size 2g --rm -v "$(pwd):/sitespeed.io" sitespeedio/sitespeed.io:16.8.1 -b chrome -n 4 -c cable --cookie perf_bar_enabled=false --cpu --outputFolder #{report_file_path} --multi --spa support/measure_scripts/repo_browser.js)).and_return(shellout_docker_run_double)

            shellout_open_double = double('Shellout', run: true)
            expect(Shellout).to receive(:new).with("open ./#{report_file_path}/index.html").and_return(shellout_open_double)

            subject.run
          end
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
