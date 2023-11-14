# frozen_string_literal: true

RSpec.describe GDK::Services do
  subject(:services) { described_class }

  describe 'ALL' do
    it 'contains Service classes' do
      service_classes = %i[
        Clickhouse
        GitLabWorkhorse
        Minio
        OpenLDAP
        PostgreSQL
        PostgreSQLReplica
        Redis
        RedisCluster
        Vault
      ]

      expect(services::ALL).to eq(service_classes)
    end
  end

  describe '.fetch' do
    it 'returns an instance of the given service name' do
      expect(services.fetch(:Redis)).to be_a(GDK::Services::Redis)
    end
  end

  describe '.enabled' do
    it 'contains enabled Service classes' do
      service_classes = [
        GDK::Services::GitLabWorkhorse,
        GDK::Services::PostgreSQL,
        GDK::Services::Redis
      ]

      expect(services.enabled.map(&:class)).to eq(service_classes)
    end
  end
end
