# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Command::Init do
  let(:deprecation_msg) { "'gdk init' is deprecated and will be removed in a future update.\n" }

  before do
    stub_no_color_env('false')
  end

  describe '#run' do
    context 'when asking for help' do
      it 'returns true', :hide_output do
        expect(subject.run(['--help'])).to be(true)
      end

      it 'displays help and exits successfully' do
        expect { subject.run(['--help']) }.to output("#{deprecation_msg}Usage: gdk init [DIR]\n").to_stdout
      end
    end

    context 'when init fails' do
      context 'because the nominated directory is invalid' do
        let(:bad_new_directory) { '-bad' }

        before do
          stub_clone_gdk(bad_new_directory)
        end

        it 'returns false', :hide_stdout do
          expect(subject.run([bad_new_directory])).to be(false)
        end

        it 'returns an error message' do
          expect { subject.run([bad_new_directory]) }.to output(deprecation_msg).to_stdout.and output("ERROR: The GDK directory cannot start with a dash.\n").to_stderr
        end
      end

      context 'because there was an issue with the git clone' do
        let(:new_directory) { 'gdk' }

        before do
          stub_clone_gdk(new_directory, success: false)
        end

        it 'returns false', :hide_output do
          expect(subject.run([new_directory])).to be(false)
        end

        it 'returns an error message' do
          expect { subject.run([new_directory]) }.to output(deprecation_msg).to_stdout.and output("ERROR: An error occurred while attempting to git clone the GDK into '#{new_directory}'.\n").to_stderr
        end
      end
    end

    context 'when init succeeds' do
      let(:new_directory) { 'gdk' }

      before do
        stub_clone_gdk(new_directory)
      end

      it 'returns true', :hide_stdout do
        expect(subject.run([new_directory])).to be(true)
      end

      it 'returns no error message' do
        expect { subject.run([new_directory]) }.to output("#{deprecation_msg}Successfully git cloned the GDK into '#{new_directory}'.\n").to_stdout
      end
    end
  end

  def stub_clone_gdk(directory, stream_output: '', success: true)
    shellout_double = instance_double(Shellout, stream: stream_output, success?: success)
    cmd = "git clone https://gitlab.com/gitlab-org/gitlab-development-kit.git #{directory}"
    allow(Shellout).to receive(:new).with(cmd).and_return(shellout_double)
  end
end
