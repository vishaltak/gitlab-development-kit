# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GDK::TaskHelpers::ClickhouseInstaller do
  let(:installed_binary_location) { GDK.config.clickhouse.dir.join('clickhouse') }

  around do |example|
    temporary_dir do
      example.run
    end
  end

  describe '#fetch_linux64' do
    it 'fetches file from LINUX_URL', :hide_output do
      expect(subject).to receive(:fetch).with(described_class::LINUX_URL, anything)

      subject.fetch_linux64
    end

    it 'returns an error message if file download fails' do
      allow(subject).to receive(:fetch)

      expect { subject.fetch_linux64 }.to output(/Failed to download ClickHouse x86_64 for Linux/).to_stderr
                                            .and output(/Download URL:/).to_stdout
    end

    it 'returns an error message when installation fails' do
      allow(subject).to receive(:fetch).and_return(true)

      expect { subject.fetch_linux64 }.to output(/Failed to extract ClickHouse x86_64 for Linux from compressed file/).to_stderr
    end

    it 'extracts downloaded file to correct location and returns a message' do
      allow(subject).to receive(:temporary_dir).and_yield(tmpdir)
      stub_gdk_yaml({
                      'clickhouse' => {
                        'dir' => File.join(tmpdir, 'gdk', 'clickhouse')
                      }
                    })

      temp_binary_path = File.join(tmpdir, 'clickhouse.tgz')
      FileUtils.cp(fixture_path.join('clickhouse-dummy.tgz'), temp_binary_path)
      allow(subject).to receive(:fetch).and_return(true)

      expect { subject.fetch_linux64 }.to output(/Installed ClickHouse for Linux x86_64/).to_stdout

      expect(File.exist?(installed_binary_location)).to be_truthy
      expect(File.executable?(installed_binary_location)).to be_truthy
    end

    context 'when previous gdk clickhouse configuration exists' do
      it 'extracts downloaded file to correct location and returns a message' do
        allow(subject).to receive(:temporary_dir).and_yield(tmpdir)
        stub_gdk_yaml({
                        'clickhouse' => {
                          'dir' => File.join(tmpdir, 'gdk', 'clickhouse'),
                          'bin' => File.join(tmpdir, 'gdk', 'clickhouse', 'another_file')
                        }
                      })

        temp_binary_path = File.join(tmpdir, 'clickhouse.tgz')
        FileUtils.cp(fixture_path.join('clickhouse-dummy.tgz'), temp_binary_path)
        allow(subject).to receive(:fetch).and_return(true)

        expect { subject.fetch_linux64 }.to output(/Installed ClickHouse for Linux x86_64/).to_stdout
                                              .and output(/The gdk.yml is pointing clickhouse.bin to a different binary/).to_stderr

        expect(File.exist?(installed_binary_location)).to be_truthy
        expect(File.executable?(installed_binary_location)).to be_truthy
      end
    end
  end

  describe '#fetch_macos_intel' do
    it 'fetches file from MACOS_INTEL_URL', :hide_output do
      expect(subject).to receive(:fetch).with(described_class::MACOS_INTEL_URL, anything)

      subject.fetch_macos_intel
    end

    it 'returns an error message if file download fails' do
      allow(subject).to receive(:fetch)

      expect { subject.fetch_macos_intel }.to output(/Failed to download ClickHouse for MacOS with Intel processor/).to_stderr
                                                .and output(/Download URL:/).to_stdout
    end

    it 'returns an error message when installation fails' do
      allow(subject).to receive(:fetch).and_return(true)

      expect { subject.fetch_macos_intel }.to output(/Failed to install ClickHouse/).to_stderr
    end

    it 'installs downloaded file to correct location and returns a message' do
      allow(subject).to receive(:temporary_dir).and_yield(tmpdir)
      stub_gdk_yaml({
                      'clickhouse' => {
                        'dir' => File.join(tmpdir, 'gdk', 'clickhouse')
                      }
                    })

      temp_binary_path = File.join(tmpdir, 'clickhouse')
      FileUtils.touch(temp_binary_path)
      allow(subject).to receive(:fetch).and_return(true)

      expect { subject.fetch_macos_intel }.to output(/Installed ClickHouse for MacOS with Intel processor/).to_stdout

      expect(File.exist?(installed_binary_location)).to be_truthy
      expect(File.executable?(installed_binary_location)).to be_truthy
    end

    context 'when previous gdk clickhouse configuration exists' do
      it 'installs downloaded file to correct location and display a warning message in addition to the installation confirmation' do
        allow(subject).to receive(:temporary_dir).and_yield(tmpdir)
        stub_gdk_yaml({
                        'clickhouse' => {
                          'dir' => File.join(tmpdir, 'gdk', 'clickhouse'),
                          'bin' => File.join(tmpdir, 'gdk', 'clickhouse', 'another_file')
                        }
                      })

        temp_binary_path = File.join(tmpdir, 'clickhouse')
        FileUtils.touch(temp_binary_path)
        allow(subject).to receive(:fetch).and_return(true)

        expect { subject.fetch_macos_intel }.to output(/Installed ClickHouse for MacOS with Intel processor/).to_stdout
                                                  .and output(/The gdk.yml is pointing clickhouse.bin to a different binary/).to_stderr

        expect(File.exist?(installed_binary_location)).to be_truthy
        expect(File.executable?(installed_binary_location)).to be_truthy
      end
    end
  end

  describe '#fetch_macos_apple_silicon' do
    it 'fetches file from MACOS_ARM64_URL', :hide_output do
      expect(subject).to receive(:fetch).with(described_class::MACOS_ARM64_URL, anything)

      subject.fetch_macos_apple_silicon
    end

    it 'returns an error message if file download fails' do
      allow(subject).to receive(:fetch)

      expect { subject.fetch_macos_apple_silicon }.to output(/Failed to download ClickHouse for MacOS with an Apple Silicon processor/).to_stderr
                                                        .and output(/Download URL:/).to_stdout
    end

    it 'returns an error message when installation fails' do
      allow(subject).to receive(:fetch).and_return(true)

      expect { subject.fetch_macos_apple_silicon }.to output(/Failed to install ClickHouse/).to_stderr
    end

    it 'installs downloaded file to correct location and returns a success message' do
      allow(subject).to receive(:temporary_dir).and_yield(tmpdir)
      stub_gdk_yaml({
                      'clickhouse' => {
                        'dir' => File.join(tmpdir, 'gdk', 'clickhouse')
                      }
                    })

      temp_binary_path = File.join(tmpdir, 'clickhouse')
      FileUtils.touch(temp_binary_path)
      allow(subject).to receive(:fetch).and_return(true)

      expect { subject.fetch_macos_apple_silicon }.to output(/Installed ClickHouse for MacOS with an Apple Silicon processor/).to_stdout

      expect(File.exist?(installed_binary_location)).to be_truthy
      expect(File.executable?(installed_binary_location)).to be_truthy
    end

    context 'when previous gdk clickhouse configuration exists' do
      it 'installs downloaded file to correct location and display a warning message in addition to the installation confirmation' do
        allow(subject).to receive(:temporary_dir).and_yield(tmpdir)
        stub_gdk_yaml({
                        'clickhouse' => {
                          'dir' => File.join(tmpdir, 'gdk', 'clickhouse'),
                          'bin' => File.join(tmpdir, 'gdk', 'clickhouse', 'another_file')
                        }
                      })

        temp_binary_path = File.join(tmpdir, 'clickhouse')
        FileUtils.touch(temp_binary_path)
        allow(subject).to receive(:fetch).and_return(true)

        expect { subject.fetch_macos_apple_silicon }.to output(/Installed ClickHouse for MacOS with an Apple Silicon processor/).to_stdout
                                                          .and output(/The gdk.yml is pointing clickhouse.bin to a different binary/).to_stderr

        expect(File.exist?(installed_binary_location)).to be_truthy
        expect(File.executable?(installed_binary_location)).to be_truthy
      end
    end
  end

  def temporary_dir(&block)
    Dir.mktmpdir('test-clickhouse') do |tmp|
      @tmpdir = tmp
      yield
    end
  end

  attr_reader :tmpdir
end
