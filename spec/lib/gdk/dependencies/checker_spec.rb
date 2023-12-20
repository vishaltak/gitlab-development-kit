# frozen_string_literal: true

RSpec.describe GDK::Dependencies::Checker do
  describe '.parse_version' do
    it 'returns the version in the string' do
      expect(described_class.parse_version('foo 1.2 bar')).to eq('1.2')
      expect(described_class.parse_version('foo 1.2.3.4.5.6 bar')).to eq('1.2.3.4.5.6')
    end

    it 'picks the first version looking number' do
      expect(described_class.parse_version("Yarn v0.1.1 2011 Author Name")).to eq('0.1.1')
      expect(described_class.parse_version('v0.1.1 2011')).to eq('0.1.1')
    end

    it 'uses the given prefix' do
      expect(described_class.parse_version('1.2.3 v4.5.6', prefix: 'v')).to eq('4.5.6')
    end

    it 'ignores suffixes' do
      expect(described_class.parse_version('1.2.3-foo+foo')).to eq('1.2.3')
    end

    it 'requires at least two numeric segments' do
      expect(described_class.parse_version('1')).to be_nil
    end
  end

  describe '#check_git_installed' do
    context 'when git is not installed' do
      it 'returns nil' do
        stub_check_binary('git', false)

        expect(subject.check_git_installed).to be false
      end
    end

    context 'when git is installed' do
      it 'returns nil' do
        stub_check_binary('git', true)

        expect(subject.check_git_installed).to be true
        expect(subject.error_messages).to be_empty
      end
    end
  end

  describe '#check_nginx_installed' do
    context 'nginx disabled' do
      it 'returns nil' do
        expect(subject.check_nginx_installed).to be_nil
        expect(subject.error_messages).to be_empty
      end
    end

    context 'nginx enabled' do
      let(:nginx_bin) { 'non-existing' }

      before do
        stub_gdk_yaml('nginx' => { 'enabled' => true, 'bin' => nginx_bin })
      end

      it 'errors when not found' do
        expect(subject.check_nginx_installed).to be_falsey
        expect(subject.error_messages).to include('ERROR: nginx is not installed or not available in your PATH.')
      end

      context 'nginx.bin points to existing executable' do
        let(:nginx_bin) { 'true' }

        it 'returns true' do
          expect(subject.check_nginx_installed).to be_truthy
          expect(subject.error_messages).to be_empty
        end
      end
    end
  end

  describe '#check_postgresql_version' do
    let(:tmp_path) { Dir.mktmpdir('gdk-path') }
    let(:pg_bin_bir) { tmp_path }
    let(:pg_version) { "psql (PostgreSQL) #{GDK::Postgresql.target_version}" }

    before do
      path = File.join(tmp_path, 'psql')
      File.open(path, File::WRONLY | File::CREAT, 0o755) do |f|
        f.write <<~SCRIPT
          #!/bin/sh
          echo '#{pg_version}'
        SCRIPT
      end

      stub_gdk_yaml("postgresql" => { "bin_dir" => tmp_path })
    end

    it 'detects the correct version' do
      expect(subject.check_postgresql_version).to be_nil
      expect(subject.error_messages).to be_empty
    end
  end

  def stub_check_binary(binary, result)
    allow(subject).to receive(:check_binary).with(binary).and_return(result)
  end
end
