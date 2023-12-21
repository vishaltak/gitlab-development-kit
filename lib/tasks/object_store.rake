# frozen_string_literal: true

namespace :object_store do
  desc 'Setup Object Store default buckets'
  task :setup do
    next unless GDK.config.object_store.enabled?

    GDK.config.object_store.objects.each do |_, data|
      minio = GDK::Services::Minio.new
      bucket_directory = minio.data_dir.join(data['bucket'])

      bucket_directory.mkpath unless bucket_directory.exist?
    end
  end
end
