# frozen_string_literal: true

RSpec.describe GDK::Diagnostic::Geo do
  subject(:geo_diagnostic) { described_class.new }

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
    context 'when Geo database does not exist' do
      before do
        stub_database_yml_content(default_content)
      end

      it 'returns true' do
        expect(geo_diagnostic.success?).to be(true)
      end
    end

    context 'when Geo database exists' do
      before do
        stub_database_yml_content(geo_content)
      end

      context 'and geo.enabled is set to true' do
        before do
          stub_geo_enabled(true)
        end

        it 'returns true' do
          expect(geo_diagnostic.success?).to be(true)
        end
      end

      context 'and geo.enabled is set to false' do
        before do
          stub_geo_enabled(false)
        end

        it 'returns false' do
          expect(geo_diagnostic.success?).to be(false)
        end
      end
    end
  end

  describe '#detail' do
    let(:success) { nil }

    before do
      allow(geo_diagnostic).to receive(:success?).and_return(success)
    end

    context 'when #success? returns true' do
      let(:success) { true }

      it 'returns nil' do
        expect(geo_diagnostic.detail).to be_nil
      end
    end

    context 'when #success? returns false' do
      context 'with GDK primary' do
        let(:success) { false }

        before do
          stub_geo_primary
        end

        it 'returns a message advising how to detail with the situation' do
          expected_detail = <<~MESSAGE
            GDK could be a Geo primary node. However, geo.enabled is not set to true in your gdk.yml.
            Update your gdk.yml to set geo.enabled to true.

            https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/geo.md
          MESSAGE

          expect(geo_diagnostic.detail).to eq(expected_detail)
        end
      end

      context 'with GDK secondary' do
        let(:success) { false }

        before do
          stub_geo_secondary
        end

        it 'returns a message advising how to detail with the situation' do
          expected_detail = <<~MESSAGE
            GDK is a Geo secondary node. #{database_yml_file} contains the geo database settings but
            geo.enabled is not set to true in your gdk.yml.

            Either update your gdk.yml to set geo.enabled to true or remove
            the geo database settings from #{database_yml_file}

            https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/geo.md
          MESSAGE

          expect(geo_diagnostic.detail).to eq(expected_detail)
        end
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
    allow_any_instance_of(GDK::Config).to receive_message_chain('geo.enabled').and_return(enabled)
  end

  def stub_geo_primary
    allow_any_instance_of(GDK::Config).to receive_message_chain('geo.secondary').and_return(nil)
  end

  def stub_geo_secondary
    allow_any_instance_of(GDK::Config).to receive_message_chain('geo.secondary').and_return(true)
  end
end
