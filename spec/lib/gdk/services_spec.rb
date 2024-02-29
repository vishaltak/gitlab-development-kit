# frozen_string_literal: true

RSpec.describe GDK::Services do
  subject(:services) { described_class }

  let(:known_services) do
    %i[
      Clickhouse
      GitLabWorkhorse
      Minio
      OpenLDAP
      PostgreSQL
      PostgreSQLReplica
      RailsWeb
      Redis
      RedisCluster
      Vault
    ]
  end

  describe '.all' do
    it 'return a list of all Service instances' do
      class_name_without_module = ->(object) { object.class.name.split('::').last.to_sym }

      services.all.each do |service|
        expect(known_services).to include(class_name_without_module.call(service))
      end
    end
  end

  describe '.all_service_names' do
    it 'contains names of Service classes' do
      expect(services.all_service_names).to match_array(known_services)
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
        GDK::Services::RailsWeb,
        GDK::Services::Redis
      ]

      expect(services.enabled.map(&:class)).to match_array(service_classes)
    end
  end
end
