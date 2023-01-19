# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Command::Config do
  before do
    stub_gdk_yaml({})
    stub_pg_bindir
    stub_no_color_env('true')
    stub_backup
  end

  context 'with no extra argument' do
    it 'aborts execution and returns usage instructions' do
      expect { subject.run([]) }.to raise_error(SystemExit).and output(/Usage:/).to_stderr
    end
  end

  context 'with invalid extra arguments' do
    it 'aborts execution and returns usage instructions' do
      expect { subject.run(%w[non-existent-command]) }.to raise_error(SystemExit).and output(/Usage:/).to_stderr
    end
  end

  context 'get' do
    context 'with valid extra arguments' do
      it 'returns values retrieved from configuration store' do
        expect { subject.run(%w[get port]) }.to output(/3000/).to_stdout
      end

      context 'with nonexistent configuration keys' do
        it 'abort execution and returns an error' do
          expect { subject.run(%w[get unknownkey]) }.to raise_error(SystemExit).and output(/Cannot get config for/).to_stderr
        end
      end
    end
  end

  context 'set' do
    context 'with a missing key' do
      it 'issues the usage warning' do
        expect { subject.run(%w[set]) }.to raise_error(SystemExit).and output(/Usage:/).to_stderr
      end
    end

    context 'with a missing value' do
      it 'issues the usage warning' do
        expect { subject.run(%w[set key]) }.to raise_error(SystemExit).and output(/Usage:/).to_stderr
      end
    end

    context 'with an invalid key' do
      it 'issues the usage warning' do
        expect { subject.run(%w[set invalidkey value]) }.to raise_error(SystemExit).and output(/ERROR: Cannot get config for 'invalidkey'/).to_stderr
      end
    end

    context 'with an invalid value' do
      it 'issues the usage warning' do
        expect { subject.run(%w[set port a]) }.to raise_error(SystemExit).and output(/ERROR: Value 'a' for setting 'port' is not a valid port/).to_stderr
      end
    end

    context 'with a valid key and value' do
      let(:current_port) { 3000 }

      context 'where the value is different' do
        it 'advises the new value has been set' do
          new_port = 3001

          stub_gdk_yaml('port' => current_port)

          expect_set("---\nport: #{new_port}\n")
          expect(GDK::Output).to receive(:success).with("'port' is now set to '#{new_port}' (previously '#{current_port}').")

          subject.run(%W[set port #{new_port}])
        end
      end

      context 'where the value is the same' do
        it 'advises the new value is the same as the current value' do
          stub_gdk_yaml('port' => current_port)

          expect_set("---\nport: #{current_port}\n")
          expect(GDK::Output).to receive(:warn).with("'port' is already set to '#{current_port}'")

          subject.run(%W[set port #{current_port}])
        end
      end

      def expect_set(yaml)
        expect(GDK::Output).to receive(:info).with("Don't forget to run 'gdk reconfigure'.")
        expect(File).to receive(:write).with(GDK::Config::FILE, yaml)
        expect(stub_backup).to receive(:backup!)
      end
    end
  end
end
