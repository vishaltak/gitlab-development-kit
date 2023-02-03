# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe GDK::Command::Doctor, :hide_output do
  # rubocop:todo RSpec/VerifiedDoubles
  let(:successful_diagnostic) { double(GDK::Diagnostic, success?: true, diagnose: nil, message: nil) }
  let(:failing_diagnostic) { double(GDK::Diagnostic, success?: false, diagnose: 'error', message: 'check failed') }
  let(:shellout) { double(Shellout, run: nil) }
  # rubocop:enable RSpec/VerifiedDoubles
  let(:diagnostics) { [] }
  let(:warning_message) do
    <<~WARNING
      ================================================================================
      Please note these warning only exist for debugging purposes and can
      help you when you encounter issues with GDK.
      If your GDK is working fine, you can safely ignore them. Thanks!
      ================================================================================
    WARNING
  end

  subject { described_class.new(diagnostics: diagnostics) }

  before do
    allow(Runit).to receive(:start).with('postgresql', quiet: true).and_return(true)
    gdk_root_stub = double('GDK_ROOT') # rubocop:todo RSpec/VerifiedDoubles
    procfile_stub = double('Procfile', exist?: true) # rubocop:todo RSpec/VerifiedDoubles
    allow(GDK).to receive(:root).and_return(gdk_root_stub)
    allow(gdk_root_stub).to receive(:join).with('Procfile').and_return(procfile_stub)
    allow(subject).to receive(:sleep).with(2)
  end

  it 'starts necessary services' do
    expect(Runit).to receive(:start).with('postgresql', quiet: true)
    expect(subject).to receive(:sleep).with(2)

    subject.run
  end

  context 'with passing diagnostics' do
    let(:diagnostics) { [successful_diagnostic, successful_diagnostic] }

    it 'runs all diagnosis' do
      expect(successful_diagnostic).to receive(:success?).twice

      subject.run
    end

    it 'prints GDK is ready.' do
      expect(GDK::Output).to receive(:success).with('Your GDK is healthy.')

      subject.run
    end
  end

  context 'with failing diagnostics' do
    let(:diagnostics) { [failing_diagnostic, failing_diagnostic] }

    it 'runs all diagnosis' do
      expect(failing_diagnostic).to receive(:success?).twice

      subject.run
    end

    it 'prints a warning' do
      expect(GDK::Output).to receive(:puts).with("\n").ordered
      expect(GDK::Output).to receive(:warn).with('Your GDK may need attention.').ordered
      expect(GDK::Output).to receive(:puts).with('check failed').ordered.twice

      subject.run
    end
  end

  context 'with partial failing diagnostics' do
    let(:diagnostics) { [failing_diagnostic, successful_diagnostic, failing_diagnostic] }

    it 'runs all diagnosis' do
      expect(failing_diagnostic).to receive(:success?).twice
      expect(successful_diagnostic).to receive(:success?).once

      subject.run
    end

    it 'prints a message from failed diagnostics' do
      expect(failing_diagnostic).to receive(:message).twice
      expect(GDK::Output).to receive(:puts).with("\n").ordered
      expect(GDK::Output).to receive(:warn).with('Your GDK may need attention.').ordered
      expect(GDK::Output).to receive(:puts).with('check failed').ordered.twice

      subject.run
    end

    it 'does not print a message from successful diagnostics' do
      expect(successful_diagnostic).not_to receive(:message)

      subject.run
    end
  end
end
