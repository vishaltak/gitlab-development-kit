# frozen_string_literal: true

RSpec.describe GDK::Command::Reconfigure do
  context 'when reconfiguration fails' do
    it 'returns an error message' do
      stub_make_reconfigure(success: false)

      expect { subject.run }.to output(/Failed to reconfigure/).to_stderr.and output(/You can try the following that may be of assistance/).to_stdout
    end
  end

  context 'when reconfiguration succeeds' do
    it 'finishes without problem' do
      stub_make_reconfigure(success: true)

      expect { subject.run }.not_to raise_error
    end
  end

  def stub_make_reconfigure(success:)
    sh = instance_double(Shellout, success?: success, stderr_str: nil)
    expect(GDK).to receive(:make).with('reconfigure').and_return(sh)
  end
end
