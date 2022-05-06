# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Command::Open do
  let(:host_os) { nil }
  let(:wait_result) { nil }
  let(:check_url_oneshot_result) { nil }

  let(:test_url_double) { instance_double(GDK::TestURL) }

  before do
    allow(RbConfig::CONFIG).to receive(:[]).with('host_os').and_return(host_os)

    allow(GDK::TestURL).to receive(:new).and_return(test_url_double)
    allow(test_url_double).to receive(:check_url_oneshot).and_return(check_url_oneshot_result)
    allow(test_url_double).to receive(:wait).and_return(wait_result)
  end

  context 'when GDK is not up' do
    let(:check_url_oneshot_result) { false }
    let(:wait_result) { false }

    it 'advises GDK is not up and returns' do
      result = nil
      expect { result = subject.run }.to output(/GDK is not up. Please run `gdk start` and try again./).to_stderr
      expect(result).to be_falsey
    end
  end

  context 'when GDK is not up initially, but then comes up' do
    let(:check_url_oneshot_result) { false }
    let(:wait_result) { true }

    it 'advises GDK is not up and returns' do
      expect(subject).to receive(:exec).with("open 'http://127.0.0.1:3000'")

      subject.run
    end
  end

  context 'when GDK is up' do
    let(:check_url_oneshot_result) { true }

    context 'when Linux' do
      let(:host_os) { 'Linux' }

      it 'calls open <GDK_URL>' do
        expect(subject).to receive(:exec).with("xdg-open 'http://127.0.0.1:3000'")

        subject.run
      end
    end

    context 'when not Linux' do
      let(:host_os) { 'Darwin' }

      it 'calls open <GDK_URL>' do
        expect(subject).to receive(:exec).with("open 'http://127.0.0.1:3000'")

        subject.run
      end
    end
  end
end
