# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Command::Open do
  let(:host_os) { nil }

  before do
    allow(RbConfig::CONFIG).to receive(:[]).with('host_os').and_return(host_os)
  end

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
