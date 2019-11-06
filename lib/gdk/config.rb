# frozen_string_literal: true

require 'etc'
require 'pathname'
require_relative 'config_settings'

module GDK
  class Config < ConfigSettings
    FILE = 'gdk.yml'

    repositories do |r|
      r.gitlab(type: :string) { 'https://gitlab.com/gitlab-org/gitlab.git' }
      r.gitlab_shell(type: :string) { 'https://gitlab.com/gitlab-org/gitlab-shell.git' }
      r.gitlab_workhorse(type: :string) { 'https://gitlab.com/gitlab-org/gitlab-workhorse.git' }
      r.gitaly(type: :string) { 'https://gitlab.com/gitlab-org/gitaly.git' }
      r.gitlab_pages(type: :string) { 'https://gitlab.com/gitlab-org/gitlab-pages.git' }
      r.gitlab_docs(type: :string) { 'https://gitlab.com/gitlab-com/gitlab-docs.git' }
    end

    git_repositories do
      # This list in not exhaustive yet, as some git repositories are based on
      # a fake GOPATH inside a projects sub directory
      %w[. gitlab]
        .map { |d| File.join(gdk_root, d) }
        .select { |d| Dir.exist?(d) }
    end

    gdk_root { Pathname.new(__dir__).parent.parent }

    gdk do |g|
      g.overwrite_changes(type: :boolean) { false }
      g.ignore_foreman(type: :boolean) { read!('.ignore-foreman') || false }
    end

    repositories_root { config.gdk_root.join('repositories') }

    hostname(type: :string) do
      next "#{config.auto_devops.gitlab.port}.qa-tunnel.gitlab.info" if config.auto_devops.enabled
      env!('host') || read!('hostname') || read!('host') || '0.0.0.0'
    end

    port(type: :integer) do
      next 443 if config.auto_devops.enabled

      env!('port') || read!('port') || 3000
    end

    https do |h|
      h.enabled(type: :boolean) do
        next true if config.auto_devops.enabled
        read!('https_enabled') || false
      end
    end

    protocol(type: :string) { config.https? ? 'https' : 'http' }

    relative_url_root(type: :string) do
      env!('relative_url_root') || read!('relative_url_root') || '/'
    end

    username(type: :string) { Etc.getpwuid.name }

    webpack do |w|
      w.host(type: :string) { read!('webpack_host') || '0.0.0.0' }
      w.port(type: :integer) { read!('webpack_port') || 3808 }
    end

    workhorse do |w|
      w.configured_port(type: :integer) { 3333 }

      w.__active_host do
        if config.auto_devops? || config.nginx?
          '0.0.0.0'
        else
          # Workhorse is the user-facing entry point whenever neither nginx nor
          # AutoDevOps is used, so in that situation use the configured GDK hostname.
          config.hostname
        end
      end

      w.__active_port do
        if config.auto_devops? || config.nginx?
          config.workhorse.configured_port
        else
          # Workhorse is the user-facing entry point whenever neither nginx nor
          # AutoDevOps is used, so in that situation use the configured GDK port.
          config.port
        end
      end
    end

    registry do |r|
      r.enabled(type: :boolean) do
        next true if config.auto_devops.enabled
        read!('registry_enabled') || false
      end

      r.host(type: :string) do
        next "#{config.auto_devops.registry.port}.qa-tunnel.gitlab.info" if config.auto_devops.enabled
        '127.0.0.1'
      end

      r.port(type: :integer) do
        read!('registry_port') || 5000
      end

      r.external_port(type: :integer) do
        next 443 if config.auto_devops.enabled
        5000
      end
    end

    object_store do |o|
      o.enabled(type: :boolean) { read!('object_store_enabled') || false }
      o.port(type: :integer) { read!('object_store_port') || 9000 }
    end

    gitlab_pages do |p|
      p.enabled(type: :boolean) { true }
      p.port(type: :integer) { read!('gitlab_pages_port') || 3010 }
    end

    auto_devops do |a|
      a.enabled(type: :boolean) { read!('auto_devops_enabled') || false }
      a.gitlab do |g|
        g.port(type: :integer) { read_or_write!('auto_devops_gitlab_port', rand(20000..24999)) }
      end
      a.registry do |r|
        r.port(type: :integer) { read!('auto_devops_registry_port') || (config.auto_devops.gitlab.port + 5000) }
      end
    end

    omniauth do |o|
      o.google_oauth2 do |g|
        g.enabled(type: :boolean) { !!read!('google_oauth_client_secret') }
        g.client_id(type: :string) { read!('google_oauth_client_id') || '' }
        g.client_secret(type: :string) { read!('google_oauth_client_secret') || '' }
      end
    end

    geo do |g|
      g.enabled(type: :boolean) { false }
    end

    elasticsearch do |e|
      e.version(type: :string) { '6.5.1' }
      e.checksum(type: :string) { '5903e1913a7c96aad96a8227517c40490825f672' }
    end

    tracer do |t|
      t.build_tags(type: :string) { 'tracer_static tracer_static_jaeger' }
      t.jaeger do |j|
        j.enabled(type: :boolean) { true }
        j.version(type: :string) { '1.10.1' }
      end
    end

    nginx do |n|
      n.enabled(type: :boolean) { false }
      n.bin(type: :string) { find_executable!('nginx') || '/usr/sbin/nginx' }
      n.ssl do |s|
        s.certificate(type: :string) { 'localhost.crt' }
        s.key(type: :string) { 'localhost.key' }
      end
      n.http do |h|
        h.enabled(type: :boolean) { false }
        h.port(type: :integer) { 80 }
      end
    end

    postgresql do |p|
      p.port(type: :integer) { read!('postgresql_port') || 5432 }
      p.bin_dir(type: :string) { cmd!(%w[support/pg_bindir]) }
      p.replication_user(type: :string) { 'gitlab_replication' }
      p.dir { config.gdk_root.join('postgresql') }
      p.data_dir { config.postgresql.dir.join('data') }
      p.replica_dir { config.gdk_root.join('postgresql-replica') }
      p.geo do |g|
        g.port(type: :integer) { read!('postgresql_geo_port') || 5432 }
        g.dir { config.gdk_root.join('postgresql-geo') }
      end
    end

    gitaly do |g|
      g.address { config.gdk_root.join('gitaly.socket') }
      g.assembly_dir { config.gdk_root.join('gitaly', 'assembly') }
      g.config_file { config.gdk_root.join('gitaly', 'gitaly.config.toml') }
      g.internal_socket_dir { config.gdk_root.join('gitaly') }
      g.log_dir { config.gdk_root.join('log', 'gitaly') }
    end

    praefect do |p|
      p.address { config.gdk_root.join('praefect.socket') }
      p.config_file { config.gdk_root.join("gitaly", "praefect.config.toml") }
      p.enabled(type: :boolean) { true }
      p.internal_socket_dir { config.gdk_root.join('gitaly', 'praefect') }
      p.node_count(type: :integer) { 1 }
      p.nodes do
        config_array!(config.praefect.node_count) do |n, i|
          n.address { config.gdk_root.join("gitaly-praefect-#{i}.socket") }
          n.config_file(type: :string) { "gitaly/gitaly-#{i}.praefect.toml" }
          n.log_dir { config.gdk_root.join("log", "praefect-gitaly-#{i}") }
          n.primary(type: :boolean) { i == 0 }
          n.service_name(type: :string) { "praefect-gitaly-#{i}" }
          n.storage(type: :string) { "praefect-internal-#{i}" }
          n.storage_dir { i == 0 ? config.repositories_root : File.join(config.repositories_root, storage) }
        end
      end
    end

    sshd do |s|
      s.bin(type: :string) { find_executable!('sshd') || '/usr/sbin/sshd' }
    end

    git do |g|
      g.bin(type: :string) { find_executable!('git') }
    end
  end
end
