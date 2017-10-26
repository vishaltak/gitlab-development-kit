admin_token = Gitlab::CurrentSettings.current_application_settings.runners_registration_token
schema = Gitlab.config.gitlab.https ? 'https://' : 'http://'

# 192.168.99.1 is the default ip virtualbox provides on host-only networks
# also docker-machine relies on this setting
gitlab_url = "#{schema}192.168.99.1:#{Gitlab.config.gitlab.port}"

Dir.chdir('..') do
  exec('gitlab-runner/out/binaries/gitlab-runner', 'register', '--non-interactive',
         '-c', "#{Dir.pwd}/gitlab-runner-config.toml",
         '--url', gitlab_url, '--registration-token', admin_token,
         '--leave-runner', '--run-untagged', '--name', 'gdk',
         '--clone-url', gitlab_url,
         '--executor', 'docker+machine',
         '--machine-machine-driver', 'virtualbox',
         '--machine-machine-name', 'gdk-%s',
         '--machine-idle-nodes', '0',
         '--machine-idle-time', 10.minutes.to_s,
         '--machine-max-builds', '10',
         '--docker-privileged',
         '--docker-image', 'alpine:latest')
end
