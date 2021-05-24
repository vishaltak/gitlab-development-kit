# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Command::Init do
  let(:deprecation_msg) { "'gdk init' is deprecated and will be removed in a future update.\n" }

  before do
    stub_no_color_env('false')
  end

  describe '#run' do
    context 'when asking for help' do
      it 'displays help and exits successfully' do
        result = nil
        expect { result = subject.run(['--help']) }.to output("#{deprecation_msg}Usage: gdk init [DIR]\n").to_stdout
        expect(result).to be(true)
      end
    end

    context 'when init fails' do
      context 'because the nominated directory is invalid' do
        it 'returns an error message' do
          result = nil
          bad_new_directory = '-bad'
          stub_clone_gdk(bad_new_directory)

          expect { result = subject.run([bad_new_directory]) }.to output(deprecation_msg).to_stdout.and output("ERROR: The GDK directory cannot start with a dash.\n").to_stderr
          expect(result).to be(false)
        end
      end

      context 'because there was an issue with the git clone' do
        it 'returns an error message' do
          result = nil
          new_directory = 'gdk'
          stub_clone_gdk(new_directory, success: false)

          expect { result = subject.run([new_directory]) }.to output(deprecation_msg).to_stdout.and output("ERROR: An error occurred while attempting to git clone the GDK into '#{new_directory}'.\n").to_stderr
          expect(result).to be(false)
        end
      end
    end

    context 'when init succeeds' do
      it 'returns no error message' do
        result = nil
        new_directory = 'gdk'
        stub_clone_gdk(new_directory)

        expect { result = subject.run([new_directory]) }.to output("#{deprecation_msg}Successfully git cloned the GDK into '#{new_directory}'.\n").to_stdout
        expect(result).to be(true)
      end
    end
  end

  def stub_clone_gdk(directory, stream_output: '', success: true)
    shellout_double = instance_double(Shellout, stream: stream_output, success?: success)
    cmd = "git clone https://gitlab.com/gitlab-org/gitlab-development-kit.git #{directory}"
    allow(Shellout).to receive(:new).with(cmd).and_return(shellout_double)
  end
end
