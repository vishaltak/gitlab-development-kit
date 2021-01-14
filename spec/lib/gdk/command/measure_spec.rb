# frozen_string_literal: true

require 'spec_helper'
require 'timecop'

RSpec.describe GDK::Command::Measure do
  let(:urls) { nil }
  let(:urls_default) { ['/explore'] }

  subject { described_class.new(urls) }

  describe '#run' do
    context 'with some requirements lacking' do
      context 'when an empty urls is provided' do
        let(:urls) { [] }

        it 'aborts' do
          expect { subject.run }.to raise_error(/Please add a URL as argument/)
        end
      end

      context "when Docker isn't installed or running " do
        let(:urls) { urls_default }

        it 'aborts' do
          stub_docker_check(success: false)

          expect { subject.run }.to raise_error(/ERROR: Docker is not installed or running!/)
        end
      end

      context "when GDK isn't running " do
        let(:urls) { urls_default }

        context 'when GDK is not running' do
          it 'aborts' do
            expect { subject.run }.to raise_error(/ERROR: GDK is not running locally/)
          end
        end

        context 'when GDK is not ready' do
          it 'aborts' do
            stub_gdk_check(http_code: 502)

            expect { subject.run }.to raise_error(/ERROR: GDK is not running locally/)
          end
        end
      end
    end

    context 'with all requirements present' do
      let(:urls) { urls_default }

      it 'runs sitespeed via Docker' do
        current_time = Time.now
        current_time_formatted = current_time.strftime('%F-%H-%M-%S')
        branch_name = 'some-branch-name'

        stub_docker_check(success: true)
        stub_gdk_check(http_code: 200)
        stub_git_rev_parse(branch_name: branch_name)

        Timecop.freeze(current_time) do
          shellout_docker_run_double = double('Shellout', stream: '')
          allow(Shellout).to receive(:new).with(%[docker run --cap-add=NET_ADMIN --shm-size 2g --rm -v "$(pwd):/sitespeed.io" sitespeedio/sitespeed.io:15.9.0 -b chrome -n 4 -c cable --cookie perf_bar_enabled=false --outputFolder sitespeed-result/some-branch-name_#{current_time_formatted} http://host.docker.internal:3000/explore]).and_return(shellout_docker_run_double)

          shellout_open_double = double('Shellout', run: true)
          allow(Shellout).to receive(:new).with("open ./sitespeed-result/#{branch_name}_#{current_time_formatted}/index.html").and_return(shellout_open_double)

          subject.run
        end
      end
    end
  end

  def stub_git_rev_parse(branch_name:)
    shellout_double = double('Shellout', run: branch_name)
    allow(Shellout).to receive(:new).with('git rev-parse --abbrev-ref HEAD', chdir: GDK.config.gitlab.dir).and_return(shellout_double)
  end

  def stub_docker_check(success:)
    shellout_double = double('Shellout', run: true, success?: success)
    allow(Shellout).to receive(:new).with('docker info').and_return(shellout_double)
  end

  def stub_gdk_check(http_code:)
    http_response_double = double('HTTP response', code: http_code.to_s)
    allow(Net::HTTP).to receive(:get_response).with(GDK.config.__uri).and_return(http_response_double)
  end
end
