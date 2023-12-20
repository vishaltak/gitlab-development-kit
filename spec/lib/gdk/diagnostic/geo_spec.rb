# frozen_string_literal: true

RSpec.describe GDK::Diagnostic::Geo do
  let(:database_yml_file) { '/home/git/gdk/gitlab/config/database.yml' }

  let(:default_content) do
    <<-CONTENT
      development:
        main:
          adapter: postgresql
          encoding: unicode
          database: gitlabhq_development
          username: postgres
          password: "secure password"
          host: localhost
          variables:
            statement_timeout: 15s
    CONTENT
  end

  let(:geo_content) do
    <<-CONTENT
      development:
        main:
          adapter: postgresql
          encoding: unicode
          database: gitlabhq_development
          username: postgres
          password: "secure password"
          host: localhost
          variables:
            statement_timeout: 15s

        geo:
          adapter: postgresql
          encoding: unicode
          database: gitlabhq_geo_development
          username: postgres
          password: "secure password"
          host: localhost
          variables:
            statement_timeout: 15s
    CONTENT
  end

  describe '#success?' do
    context "when Geo database settings doesn't exist" do
      before do
        stub_database_yml_content(default_content)
      end

      context 'and geo.enabled is set to false' do
        it 'returns true' do
          stub_geo_enabled(false)

          expect(subject.success?).to be_truthy
        end
      end

      context 'and geo.enabled is set to true' do
        it 'returns false' do
          stub_geo_enabled(true)

          expect(subject.success?).to be_falsy
        end
      end
    end

    context 'when Geo database settings does exist' do
      before do
        stub_database_yml_content(geo_content)
      end

      context 'and geo.enabled is set to false' do
        it 'returns false' do
          stub_geo_enabled(false)

          expect(subject.success?).to be_falsy
        end
      end

      context 'and geo.enabled is set to true' do
        it 'returns true' do
          stub_geo_enabled(true)

          expect(subject.success?).to be_truthy
        end
      end
    end
  end

  describe '#detail' do
    let(:success) { nil }

    before do
      allow(subject).to receive(:success?).and_return(success)
    end

    context 'when #success? returns true' do
      let(:success) { true }

      it 'returns nil' do
        expect(subject.detail).to be_nil
      end
    end

    context 'when #success? returns false' do
      let(:success) { false }

      it 'returns a message advising how to detail with the situation' do
        expected_detail = <<~MESSAGE
          #{database_yml_file} contains the geo database settings but
          geo.enabled is not set to true in your gdk.yml.

          Either update your gdk.yml to set geo.enabled to true or remove
          the geo database settings from #{database_yml_file}

          https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/geo.md
        MESSAGE

        expect(subject.detail).to eq(expected_detail)
      end
    end
  end

  def stub_database_yml_content(content)
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(database_yml_file).and_return(true)

    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with(database_yml_file).and_return(content)
  end

  def stub_geo_enabled(enabled)
    gdk_geo_config = double('geo config', enabled: enabled) # rubocop:todo RSpec/VerifiedDoubles
    allow_any_instance_of(GDK::Config).to receive(:geo).and_return(gdk_geo_config)
  end
end
