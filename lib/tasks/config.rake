# frozen_string_literal: true

require_relative '../gdk/task_helpers'

CONFIGS = FileList[
  'Procfile',
  'gdk.example.yml',
  'support/makefiles/Makefile.config.mk',
  'nginx/conf/nginx.conf',
  'gitlab/config/gitlab.yml',
  'prometheus/prometheus.yml',
  'redis/redis.conf',
  'clickhouse/config.xml',
  'clickhouse/users.xml',
  'clickhouse/config.d/data-paths.xml',
  'clickhouse/config.d/gdk.xml',
  'clickhouse/config.d/logger.xml',
  'clickhouse/config.d/openssl.xml',
  'clickhouse/config.d/user-directories.xml',
  'clickhouse/users.d/gdk.xml'
]
CLOBBER.include(*CONFIGS)

desc 'Dump the configured settings'
task 'dump_config' do
  puts GDK.config.dump_as_yaml
end

desc 'Generate an example config file with all the defaults'
file 'gdk.example.yml' => 'clobber:gdk.example.yml' do |t|
  require 'gdk/config_example'

  begin
    yaml = GDK::ConfigExample.new.dump_as_yaml
    File.open(t.name, File::CREAT | File::TRUNC | File::WRONLY).write(yaml)
  rescue TypeError => e
    GDK::Output.abort(e)
  end
end

desc 'Regenerate all config files from scratch'
task reconfigure: [:all]

desc 'Generate all config files'
task all: CONFIGS

desc nil
task 'clobber:gdk.example.yml' do |t|
  Rake::Cleaner.cleanup_files([t.name])
end

file GDK::Config::FILE do |t|
  FileUtils.touch(t.name)
end

desc nil
task 'generate-file-at', [:file, :destination] do |_, args|
  file = args[:file]
  destination = args[:destination]
  source = Rake::Task[file].source

  GDK::ErbRenderer.new(source, destination).render!
end

# Define as a task instead of a file, so it's built unconditionally
desc nil
task 'gdk-config.mk' => 'support/templates/makefiles/gdk-config.mk.erb' do |t|
  GDK::ErbRenderer.new(t.source, t.name).render!
  puts t.name # Print the filename, so make can include it
end

desc 'Generate gitaly config toml'
file 'gitaly/gitaly.config.toml' => ['support/templates/gitaly/gitaly.config.toml.erb'] do |t|
  GDK::ErbRenderer.new(
    t.source,
    t.name,
    node: GDK.config.gitaly
  ).safe_render!

  GDK.config.gitaly.__storages.each do |storage|
    FileUtils.mkdir_p(storage.path)
  end

  FileUtils.mkdir_p(GDK.config.gitaly.log_dir)
  FileUtils.mkdir_p(GDK.config.gitaly.runtime_dir)
end

file 'gitaly/praefect.config.toml' => ['support/templates/gitaly/praefect.config.toml.erb'] do |t|
  GDK::ErbRenderer.new(t.source, t.name).render!

  GDK.config.praefect.__nodes.each_with_index do |node, _|
    Rake::Task[node['config_file']].invoke
  end
end

GDK.config.praefect.__nodes.each do |node|
  desc "Generate gitaly config for #{node['storage']}"
  file node['config_file'] => ['support/templates/gitaly/gitaly.config.toml.erb'] do |t|
    GDK::ErbRenderer.new(
      t.source,
      t.name,
      node: node
    ).safe_render!

    node.__storages.each do |storage|
      FileUtils.mkdir_p(storage.path)
    end

    FileUtils.mkdir_p(node['log_dir'])
    FileUtils.mkdir_p(node['runtime_dir'])
  end
end

tasks = GDK::TaskHelpers::ConfigTasks.instance

# Template tasks
tasks.add_template(name: 'Procfile')
tasks.add_template(name: 'gitlab/config/cable.yml')
tasks.add_template(name: 'gitlab/config/database.yml')
tasks.add_template(name: 'gitlab/config/gitlab.yml')
tasks.add_template(name: 'gitlab/config/puma.rb')
tasks.add_template(name: 'gitlab/config/redis.cache.yml', template: 'support/templates/gitlab/config/redis.sessions.yml.erb', erb_extra_args: { cluster: :rate_limiting })
tasks.add_template(name: 'gitlab/config/redis.queues.yml', template: 'support/templates/gitlab/config/redis.sessions.yml.erb', erb_extra_args: { cluster: :queues })
tasks.add_template(name: 'gitlab/config/redis.rate_limiting.yml', template: 'support/templates/gitlab/config/redis.sessions.yml.erb', erb_extra_args: { cluster: :rate_limiting })
tasks.add_template(name: 'gitlab/config/redis.sessions.yml', erb_extra_args: { cluster: :sessions })
tasks.add_template(name: 'gitlab/config/redis.shared_state.yml', template: 'support/templates/gitlab/config/redis.sessions.yml.erb', erb_extra_args: { cluster: :shared_state })
tasks.add_template(name: 'gitlab/config/redis.trace_chunks.yml', template: 'support/templates/gitlab/config/redis.sessions.yml.erb', erb_extra_args: { cluster: :trace_chunks })
tasks.add_template(name: 'gitlab/config/resque.yml', template: 'support/templates/gitlab/config/redis.sessions.yml.erb', erb_extra_args: { cluster: :shared_state })
tasks.add_template(name: 'gitlab/workhorse/config.toml')
tasks.add_template(name: 'gitlab-k8s-agent-config.yml')
tasks.add_template(name: 'gitlab-pages/gitlab-pages.conf', make_dependencies: ['gitlab-pages/.git'])
tasks.add_template(name: 'gitlab-pages-secret')
tasks.add_template(name: 'gitlab-runner-config.toml', no_op_condition: 'runner_enabled')
tasks.add_template(name: 'gitlab-shell/config.yml', make_dependencies: ['gitlab-shell/.git'])
tasks.add_template(name: 'gitlab-spamcheck/config/config.toml')
tasks.add_template(name: 'grafana/grafana.ini')
tasks.add_template(name: 'nginx/conf/nginx.conf')
tasks.add_template(name: 'openssh/sshd_config')
tasks.add_template(name: 'prometheus/prometheus.yml', post_render: ->(task) { chmod('+r', task.name, verbose: false) })
tasks.add_template(name: 'redis/redis.conf')
tasks.add_template(name: 'registry/config.yml', make_dependencies: ['registry_host.crt'])
tasks.add_template(name: 'snowplow/snowplow_micro.conf', post_render: ->(task) { chmod('+r', task.name, verbose: false) })
tasks.add_template(name: 'snowplow/iglu.json', post_render: ->(task) { chmod('+r', task.name, verbose: false) })
tasks.add_template(name: 'clickhouse/config.xml', template: 'support/templates/clickhouse/config.xml')
tasks.add_template(name: 'clickhouse/users.xml', template: 'support/templates/clickhouse/users.xml')
tasks.add_template(name: 'clickhouse/config.d/data-paths.xml')
tasks.add_template(name: 'clickhouse/config.d/gdk.xml')
tasks.add_template(name: 'clickhouse/config.d/logger.xml')
tasks.add_template(name: 'clickhouse/config.d/openssl.xml')
tasks.add_template(name: 'clickhouse/config.d/user-directories.xml')
tasks.add_template(name: 'clickhouse/users.d/gdk.xml')
tasks.add_template(name: 'elasticsearch/config/elasticsearch.yml', template: 'support/templates/elasticsearch/config/elasticsearch.yml', no_op_condition: 'elasticsearch_enabled')
tasks.add_template(name: 'elasticsearch/config/jvm.options.d/custom.options', template: 'support/templates/elasticsearch/config/jvm.options.d/custom.options', no_op_condition: 'elasticsearch_enabled')

# Make targets
tasks.add_make_task(name: 'gitlab-db-migrate', make_dependencies: ['ensure-databases-running'])
tasks.add_make_task(name: 'preflight-checks', timed: true)
tasks.add_make_task(name: 'preflight-update-checks', timed: true)
tasks.add_make_task(name: 'gitaly/gitaly.config.toml')
tasks.add_make_task(name: 'gitaly/praefect.config.toml')

# Generate a file task for each template we manage
tasks.template_tasks.each do |task|
  desc "Generate #{task.name}"
  file task.name => [task.template, GDK::Config::FILE] do |t, args|
    GDK::ErbRenderer.new(t.source, t.name, **task.erb_extra_args).safe_render!
    task.post_render&.call(t)
  end
end

desc 'Dynamically generate Make targets for Rake tasks'
file 'support/makefiles/Makefile.config.mk' => Dir['lib/**/*'] do |t, _|
  GDK::ErbRenderer.new(
    'support/templates/makefiles/Makefile.config.mk.erb',
    t.name,
    tasks: tasks.all_tasks
  ).safe_render!
end

desc 'Show all the claimed ports'
task :claimed_ports do
  config = GDK::Config.new.tap(&:validate!)

  printf("\n| %5s | %-20s |\n", 'Port', 'Service')
  printf("| %5s | %20s |\n", '-' * 5, '-' * 20)

  config.port_manager.claimed_ports_and_services.keys.sort.each do |p|
    printf("| %5d | %-20s |\n", p, config.port_manager.claimed_service_for_port(p))
  end
end
