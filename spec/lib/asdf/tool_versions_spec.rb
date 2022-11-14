# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Asdf::ToolVersions do
  let(:software_name) { 'golang' }
  let(:wanted_software_version) { '1.17.2' }
  let(:wanted_software_tool_version) { Asdf::ToolVersion.new(software_name, wanted_software_version) }
  let(:unnecessary_software_version) { '1.17.1' }
  let(:unnecessary_software_tool_version) { Asdf::ToolVersion.new(software_name, unnecessary_software_version) }
  let(:tmp_dir_we_pretend_exists) { '/tmp/dir/that/we/pretend/exists/asdf' }

  subject { described_class.new }

  describe '#default_tool_version_for' do
    context 'postgres' do
      it 'returns instance of Asdf::ToolVersion' do
        tool_version = subject.default_tool_version_for('postgres')

        expect(tool_version).to be_instance_of(Asdf::ToolVersion)
        expect(tool_version.version).to eq('12.13')
      end
    end
  end

  describe '#default_version_for' do
    context 'postgres' do
      it 'returns 12.13' do
        expect(subject.default_version_for('postgres')).to eq('12.13')
      end
    end
  end

  describe '#unnecessary_software_to_uninstall?' do
    before do
      stub_asdf_data_installs_dir(tmp_dir_we_pretend_exists, exist: true)
    end

    context "when there isn't any software to uninstall" do
      it 'returns false' do
        stub_no_unnecessary_installed_software

        expect(subject.unnecessary_software_to_uninstall?).to be_falsey
      end
    end

    context 'when there is software to uninstall' do
      it 'returns true' do
        stub_some_unnecessary_installed_software

        expect(subject.unnecessary_software_to_uninstall?).to be_truthy
      end
    end
  end

  describe '#unnecessary_installed_versions_of_software' do
    before do
      stub_some_unnecessary_installed_software
    end

    it 'returns a Hash of software and versions that can be uninstalled' do
      expect(subject.unnecessary_installed_versions_of_software).to be_a(Hash)
    end

    it 'contains golang 1.17.1' do
      unnecessary_installed_versions_of_software = subject.unnecessary_installed_versions_of_software

      expect(unnecessary_installed_versions_of_software).to include(software_name => { unnecessary_software_version => unnecessary_software_tool_version })
    end
  end

  describe '#uninstall_unnecessary_software!' do
    context 'when asdf installs directory does not exist (asdf not in use)' do
      it 'informs and returns true' do
        non_existent_asdf_dir = '/tmp/dir/that/doesnt/exist/asdf'
        stub_asdf_data_installs_dir(non_existent_asdf_dir, exist: false)

        expect(GDK::Output).to receive(:info).with("Skipping because '#{non_existent_asdf_dir}/installs' does not exist.")

        expect(subject.uninstall_unnecessary_software!).to be_truthy
      end
    end

    context 'when asdf installs directory does exist' do
      before do
        stub_asdf_data_installs_dir(tmp_dir_we_pretend_exists, exist: true)
      end

      context 'when asdf.opt_out is set to true' do
        it 'informs and returns true' do
          allow_any_instance_of(GDK::Config).to receive_message_chain('asdf.opt_out?').and_return(true)

          expect(GDK::Output).to receive(:info).with('Skipping because asdf.opt_out is set to true.')

          expect(subject.uninstall_unnecessary_software!).to be_truthy
        end
      end

      context 'when there is no software to uninstall' do
        it 'informs and returns true' do
          stub_no_unnecessary_installed_software

          expect(GDK::Output).to receive(:info).with('No unnecessary asdf software to uninstall.')

          expect(subject.uninstall_unnecessary_software!).to be_truthy
        end
      end

      context 'when there is software to uninstall' do
        before do
          stub_some_unnecessary_installed_software
        end

        context 'when prompted' do
          context 'and the user accepts' do
            context 'but an unhandled exception occurs' do
              it 'aborts with exception', :hide_output do
                stub_prompt('y')

                expect_warn_and_puts
                expect(unnecessary_software_tool_version).to receive(:uninstall!).and_raise(StandardError)

                expect { subject.uninstall_unnecessary_software! }.to raise_error(StandardError)
              end
            end

            context 'but the uninstall command returns a non-zero exit code' do
              it 'return false' do
                stub_prompt('y')

                expect_warn_and_puts
                expect(unnecessary_software_tool_version).to receive(:uninstall!).and_raise(Asdf::ToolVersion::UninstallFailedError)
                expect_uninstall_failure

                expect(subject.uninstall_unnecessary_software!).to be_falsey
              end
            end
          end

          context 'but the user does not accept' do
            it 'does not uninstall and returns true' do
              stub_prompt('n')

              expect_warn_and_puts
              expect(unnecessary_software_tool_version).not_to receive(:uninstall!)

              expect(subject.uninstall_unnecessary_software!).to be_truthy
            end
          end

          context 'when software succeeds in uninstalling' do
            context 'and the user accepts' do
              context 'by setting GDK_ASDF_UNINSTALL_UNNECESSARY_SOFTWARE_CONFIRM to true' do
                it 'uninstalls returns true' do
                  stub_env('GDK_ASDF_UNINSTALL_UNNECESSARY_SOFTWARE_CONFIRM', 'true')

                  expect_warn_and_puts
                  expect(unnecessary_software_tool_version).to receive(:uninstall!).and_return(true)
                  expect_uninstall_success

                  expect(subject.uninstall_unnecessary_software!).to be_truthy
                end
              end

              context 'via a direct response' do
                it 'uninstalls returns true' do
                  stub_prompt('y')

                  expect_warn_and_puts
                  expect(unnecessary_software_tool_version).to receive(:uninstall!).and_return(true)
                  expect_uninstall_success

                  expect(subject.uninstall_unnecessary_software!).to be_truthy
                end
              end
            end
          end
        end

        context 'when asked to not prompt' do
          context 'when software succeeds in uninstalling' do
            it 'returns true' do
              expect(GDK::Output).not_to receive(:warn).with('About to uninstall the following asdf software:')
              expect(GDK::Output).not_to receive(:puts).with("#{software_name} #{unnecessary_software_version}")
              expect(GDK::Output).not_to receive(:prompt).with('Are you sure? [y/N]')

              expect(unnecessary_software_tool_version).to receive(:uninstall!).and_return(true)
              expect_uninstall_success

              expect(subject.uninstall_unnecessary_software!(prompt: false)).to be_truthy
            end
          end
        end
      end
    end

    def stub_prompt(response)
      allow(GDK::Output).to receive(:interactive?).and_return(true)
      allow(GDK::Output).to receive(:prompt).with('Are you sure? [y/N]').and_return(response)
    end

    def expect_warn_and_puts
      expect(GDK::Output).to receive(:warn).with('About to uninstall the following asdf software:').ordered
      expect(GDK::Output).to receive(:puts).with(stderr: true).ordered
      expect(GDK::Output).to receive(:puts).with("#{software_name} #{unnecessary_software_version}").ordered
      expect(GDK::Output).to receive(:puts).with(stderr: true).ordered
    end

    def expect_uninstall_info
      expect(GDK::Output).to receive(:print).with("Uninstalling #{software_name} ").ordered
      expect(GDK::Output).to receive(:print).with(unnecessary_software_version).ordered
    end

    def expect_uninstall_success
      expect_uninstall_info
      expect(GDK::Output).to receive(:puts).with(" #{GDK::Output.icon(:success)}").ordered
    end

    def expect_uninstall_failure
      expect_uninstall_info
      expect(GDK::Output).to receive(:puts).with(" #{GDK::Output.icon(:error)}").ordered
      expect(GDK::Output).to receive(:puts).with(stderr: true).ordered
      expect(GDK::Output).to receive(:warn).with("Failed to uninstall the following:\n\n").ordered
      expect(GDK::Output).to receive(:puts).with("#{software_name} #{unnecessary_software_version}").ordered
    end
  end

  def stub_asdf_data_installs_dir(dir, exist:)
    stub_env('HOME', '/home/gdk')
    stub_env('ASDF_DATA_DIR', dir)

    asdf_data_installs_dir_double = instance_double(Pathname, exist?: exist, to_s: "#{dir}/installs")
    asdf_data_dir_double = instance_double(Pathname, join: asdf_data_installs_dir_double)
    allow(Pathname).to receive(:new).and_call_original
    allow(Pathname).to receive(:new).with(dir).and_return(asdf_data_dir_double)
  end

  def stub_no_unnecessary_installed_software
    stub_software(wanted_version: wanted_software_version,
                  wanted_tool_version: wanted_software_tool_version,
                  installed_version: wanted_software_version,
                  installed_tool_version: wanted_software_tool_version
                 )
  end

  def stub_some_unnecessary_installed_software
    stub_software(wanted_version: wanted_software_version,
                  wanted_tool_version: wanted_software_tool_version,
                  installed_version: unnecessary_software_version,
                  installed_tool_version: unnecessary_software_tool_version
                 )
  end

  def stub_software(wanted_version:, wanted_tool_version:, installed_version:, installed_tool_version:)
    allow(Asdf::ToolVersion).to receive(:new).and_call_original

    wanted_software_lines = ['# line to be ignored', "#{software_name} #{wanted_version}"]
    allow(subject).to receive(:raw_tool_versions_lines).and_return(wanted_software_lines)
    allow(Asdf::ToolVersion).to receive(:new).with(software_name, wanted_version).and_return(wanted_tool_version)

    software_install_dirs = [Pathname.new("/tmp/.asdf_fake/installs/#{software_name}/#{installed_version}")]
    allow(subject).to receive(:asdf_install_dirs_for).with(software_name).and_return(software_install_dirs)
    allow(Asdf::ToolVersion).to receive(:new).with(software_name, installed_version).and_return(installed_tool_version)
  end
end
