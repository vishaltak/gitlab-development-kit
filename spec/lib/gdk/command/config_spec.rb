# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::Command::Config do
  before do
    stub_gdk_yaml({})
    stub_no_color_env('true')
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
        it 'abort execution and returns an error when configuration keys cant be found' do
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
        expect { subject.run(%w[set port a]) }.to raise_error(SystemExit).and output(/ERROR: 'a' does not appear to be a valid Integer/).to_stderr
      end
    end

    context 'with a valid key and value' do
      context 'but the value is already set' do
        it 'advises the key is already set to that value' do
          expect { subject.run(%w[set port 3000]) }.to output(/'port' is already set to '3000/).to_stdout
        end
      end

      context 'and the value is different' do
        it 'advised the new value has been set' do
          new_port = 3001

          freeze_time do
            stub_gdk_yml_backup_and_save(Time.now, "---\nport: #{new_port}\n")

            expect(GDK::Output).to receive(:info).with("'port' is now set to '#{new_port}' (previously '3000').")

            subject.run(%W[set port #{new_port}])
          end
        end
      end
    end
  end
end
