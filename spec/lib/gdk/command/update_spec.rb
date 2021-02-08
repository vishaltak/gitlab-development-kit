# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Command::Update do
  before do
    allow(GDK).to receive(:execute_hooks)
    allow(GDK).to receive(:make)
  end

  describe '#run' do
    context 'when update fails' do
      it 'displays an error message' do
        stub_no_color_env('true')
        allow(subject).to receive(:update!)

        expect { subject.run }.to output(/ERROR: Failed to update/).to_stderr.and output(/You can try the following that may be of assistance/).to_stdout
      end
    end

    it 'delegates to #update! and executess with success' do
      expect(subject).to receive(:update!).and_return('some content')
      expect(subject).not_to receive(:reconfigure!)

      subject.run
    end

    context 'when gdk.experimental.auto_reconfigure flag is enabled' do
      before do
        yaml = {
          'gdk' => {
            'experimental' => {
              'auto_reconfigure' => true
            }
          }
        }
        stub_gdk_yaml(yaml)
      end

      it 'executes executes reconfigure command after update' do
        expect(subject).to receive(:update!).and_return('some content')
        expect(subject).to receive(:reconfigure!)

        subject.run
      end
    end
  end
end
