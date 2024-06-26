# Troubleshooting GDK

Before attempting the specific troubleshooting steps documented below, many problems can be resolved
by:

- Running the following commands:

  ```shell
  cd <gdk-dir>/gitlab
  yarn install && bundle install
  bundle exec rails db:migrate RAILS_ENV=development
  ```

  This installs required Node.js modules and Ruby gems, and performs database migrations, which can
  fix errors caused by switching branches.

- [Updating GDK](../index.md#update-gdk).

## Sections

GDK troubleshooting information is available for the following:

- [Installing the GDK](#installing-the-gdk)
- [Apple M1/M2 machines](apple_mx_machines.md)
- [asdf](asdf.md)
- [Ruby](ruby.md)
- [Node.js](node_js.md)
- [PostgreSQL](postgresql.md)
- [Git](#git)
- [Webpack](webpack.md)
- [Running tests](running_tests.md)
- [Puma](#puma)
- [Sidekiq Cluster](#sidekiq-cluster)
- [Jaeger](#jaeger)
- [Gitaly](#gitaly)
- [Elasticsearch](#elasticsearch)
- [Homebrew](#homebrew)
- [Live reloading](#live-reloading)
- [Praefect](#praefect)
- [Starting the GDK](#starting-the-gdk)
- [Stopping and restarting the GDK](#stopping-and-restarting-the-gdk)

If you can't solve your problem, or if you have a problem in another area, open an
issue on the [GDK issue tracker](https://gitlab.com/gitlab-org/gitlab-development-kit/issues).

## Installing the GDK

### No keyserver available

If you see the following error while `asdf` tries to install dependencies as part of the GDK installation:

```shell
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  3490    0  3490    0     0  45921      0 --:--:-- --:--:-- --:--:-- 45921
gpg: keyserver receive failed: Network is unreachable
gpg: keyserver receive failed: No keyserver available
[...]
ERROR: Failed to install some asdf tools.
```

You can fix it by running:

```shell
echo "standard-resolver" >  ~/.gnupg/dirmngr.conf
sudo pkill dirmngr
```

See this [issue](https://github.com/asdf-vm/asdf-nodejs/issues/192) for more details.

### `icuc4` setup failed during `make .gitlab-translations` in GDK installation

If you encounter an `icuc4` setup error during the `make .gitlab-translations` step of GDK installation, try the following steps:

1. Upgrade Xcode to the latest version.
1. Run `brew cleanup` to clean up any unnecessary files.
1. Run `brew upgrade` to upgrade outdated packages.
1. Open a new terminal window and continue with the installation of GDK.

### PostgreSQL socket creation failed due to GDK directory path being too long

If you encounter a PostgreSQL socket creation failure, it might be because Gitaly is unable to create a Unix socket due to your GDK directory path exceeding the supported character limit.

To fix this issue, try moving the GDK directory to a location with a shorter directory path, then continue with your GDK setup.

## Git

The following are possible solutions to problems you might encounter with Git and GDK.

### 'Invalid reference name' when creating a new tag

Make sure that `git` is configured correctly on your development
machine (where GDK runs).

```shell
git checkout -b can-I-commit
git commit --allow-empty -m 'I can commit'
```

### `fatal: not a git repository`

If any `gdk` command gives you the following error:

```plaintext
fatal: not a git repository (or any of the parent directories): .git
```

Make sure you don't have `gdk` aliased in your shell.
For example the Git module in [prezto](https://github.com/sorin-ionescu/prezto)
has an [alias](https://github.com/sorin-ionescu/prezto/blob/master/modules/git/README.md#data)
for `gdk` that lists killed files.

## Puma

The following are possible solutions to problems you might encounter with Puma and GDK.

### An error has occurred and reported in the system's low-level handler

If you receive this error message:

```plaintext
An error has occurred and reported in the system's low-level error handler.
```

This is [Puma](https://github.com/puma/puma) catching an error that has slipped through from Rails. Here are some suggestions that may assist:

- Completely stop your GDK to rule out an out-of-date process running:

  ```shell
  gdk stop && gdk kill && gdk start
  ```

- Update your GDK as the problem may have already been fixed:

  ```shell
  gdk update && gdk restart
  ```

- If the problem continues to persist, please raise a GDK Issue ensuring all detail requested in the Issue template is provided.

### Puma timeout

Browser shows `EOF`. Logs show a timeout:

```plaintext
error: GET "/users/sign_in": badgateway: failed after 62s: EOF
```

Depending on the performance of your development environment, Puma may
time out. Increase the timeout as a workaround.

Use environment variables to override the default timeout:

Variable | Type | Description
-------- | ---- | -----------
`GITLAB_RAILS_RACK_TIMEOUT` | integer | Sets `service_timeout`
`GITLAB_RAILS_WAIT_TIMEOUT` | integer | Sets `wait_timeout`

## Sidekiq Cluster

GDK uses Sidekiq Cluster (running a single Sidekiq process) by default instead
`bundle exec sidekiq` directly, which is a step towards making development a
bit more like production.

Technically, running Sidekiq Cluster with a single Sidekiq process matches the same behavior
of running Sidekiq directly, but eventually problems may arise.

If you're experiencing performance issues or jobs not being picked up, try disabling
Sidekiq Cluster by:

1. Stopping all running processes with `gdk stop`.
1. Opening the `$GDKROOT/Procfile` file.
1. Removing the `SIDEKIQ_WORKERS` environment variable from `rails-background-jobs`.
1. Starting GDK again with `gdk start`.

When doing so, please create an issue describing what happened.

## Jaeger

If you're seeing errors such as:

```shell
ERROR -- : Failure while sending a batch of spans: Failed to open TCP connection to localhost:14268 (Connection refused - connect(2) for "localhost" port 14268)
```

This is most likely because Jaeger is not configured in your `$GDKROOT/Procfile`.
The easiest way to fix this is by re-creating your `Procfile` and then running
a `gdk reconfigure`:

1. `mv Procfile Procfile.old; make Procfile`
1. `gdk reconfigure`

For more information about Jaeger, visit the
[distributed tracing GitLab developer documentation](https://docs.gitlab.com/ee/development/distributed_tracing.html).

## Gitaly

The following are possible solutions to problems you might encounter with Gitaly and GDK.

### `config.toml: no such file or directory`

If you see errors such as:

```shell
07:23:16 gitaly.1                | time="2019-05-17T07:23:16-05:00" level=fatal msg="load config" config_path=<path-to-gdk>/gitaly/gitaly.config.toml error="open <path-to-gdk>/gitaly/gitaly.config.toml: no such file or directory"
```

Somehow, `gitaly/gitaly.config.toml` is missing. You can re-create this file by running
the following in your GDK directory:

```shell
make gitaly-setup
```

### Git fails to compile within Gitaly project

If you see the following error when running a `gdk update`:

```shell
ld: library not found for -lgit2
```

A known fix is to clean your Go cache by running the following from the GDK's root
directory:

```shell
go clean -cache
rm -rf gitaly
```

Now rerun `gdk update`.

### `libegit2.a Error 129`

If you see the following error when running a `gdk install` or a `gdk update`:

```shell
make[1]: Entering directory '/home/user/gitlab-development-kit/gitaly; error: unknown option `initial-branch=master'
make[1]: *** [Makefile:424: /home/user/gitlab-development-kit/gitaly/_build/deps/libgit2/install/lib/libgit2.a] Error 129
```

Check which version of Git you're running with `git --version`, and compare it against
[GitLab requirements](https://docs.gitlab.com/ee/install/requirements.html#git-versions). You
might be running an unsupported version.

If the supported version is not available for you from pre-compiled packages, try following the
instructions for:

- [Ubuntu or Debian](../index.md#ubuntu-or-debian).
- [Arch and Manjaro](../index.md#arch-and-manjaro-linux).

If that doesn't give you the supported version, you might have to [compile Git from source](https://docs.gitlab.com/ee/install/installation.html#git).

## Elasticsearch

Running a spec locally may give you something like the following:

```shell
rake aborted!
Gitlab::TaskFailedError: # pkg-config --cflags  -- icu-i18n icu-i18n
Package icu-i18n was not found in the pkg-config search path.
Perhaps you should add the directory containing `icu-i18n.pc'
to the PKG_CONFIG_PATH environment variable
No package 'icu-i18n' found
Package icu-i18n was not found in the pkg-config search path.
Perhaps you should add the directory containing `icu-i18n.pc'
to the PKG_CONFIG_PATH environment variable
No package 'icu-i18n' found
pkg-config: exit status 1
make: *** [build] Error 2
```

This indicates that Go is trying to link (unsuccessfully) to brew's `icu4c`.

Find the directory where `icu-i18n.pc` resides:

- On macOS, using [Homebrew](https://brew.sh/), it is generally in `/usr/local/opt/icu4c/lib/pkgconfig` or `/opt/homebrew/opt/icu4c/lib/pkgconfig`
- On Ubuntu/Debian it might be in `/usr/lib/x86_64-linux-gnu/pkgconfig`
- On Fedora it is expected to be in `/usr/lib64/pkgconfig`

You need to add that directory to the `PKG_CONFIG_PATH` environment variable.

To fix this now, run the following on the command line:

```shell
export PKG_CONFIG_PATH="/usr/local/opt/icu4c/lib/pkgconfig:$PKG_CONFIG_PATH"
```

To fix this for the future, add the line above to `~/.bash_profile` or `~/.zshrc`.

### Elasticsearch indexer looks for the wrong version of icu4c

You might get the following error when updating the application:

```plaintext
# gitlab.com/gitlab-org/gitlab-elasticsearch-indexer
/usr/local/Cellar/go/1.14.2_1/libexec/pkg/tool/darwin_amd64/link: running clang failed: exit status 1
ld: warning: directory not found for option '-L/usr/local/Cellar/icu4c/64.2/lib'
ld: library not found for -licui18n
clang: error: linker command failed with exit code 1 (use -v to see invocation)

make[1]: *** [build] Error 2
make: *** [gitlab-elasticsearch-indexer/bin/gitlab-elasticsearch-indexer] Error 2
```

This means Go is trying to link to brew's version of `icu4c` (`64.2` in the example), and failing.
This can happen when `icu4c` is not pinned and got updated. Verify the version with:

```shell
$ ls /usr/local/Cellar/icu4c
66.1
```

Clean Go's cache to fix this error. From the GDK's root directory:

```shell
cd gitlab-elasticsearch-indexer/
go clean -cache
```

## Homebrew

Most `brew` problems can be figured out by running:

```shell
brew doctor
```

However, older installations may have significant cruft leftover from previous
installations and updates. To manually remove outdated downloads for all
formulae, casks, and stale lock files, run:

```shell
brew cleanup
```

For more information on uninstalling old versions of a formula, see the [Homebrew FAQ](https://docs.brew.sh/FAQ#how-do-i-uninstall-old-versions-of-a-formula).
For additional troubleshooting information, see the Homebrew [Common Issues](https://docs.brew.sh/Common-Issues) page.

## Live reloading

If you previously compiled production assets with `bundle exec rake gitlab:assets:compile`, the GDK
serves the assets from the `public/assets/` directory, which means that changing SCSS files doesn't
have any effect in development until you recompile the assets manually.

To re-enable live reloading of CSS in development, remove the `public/assets/` directory and restart
GDK.

## Praefect

### get shard for "default": primary is not healthy

From the GDK's root directory:

```shell
cd gitaly/ruby
bundle install
```

You may need to run a `gdk restart` for the changes to take effect.

### `/home/user/gitlab-development-kit/gitaly/_build/bin/praefect`: No such file or directory

You might encounter the following error while running Gitaly database migrations:

```shell
support/migrate-praefect: line 4: /home/user/gitlab-development-kit/gitaly/_build/bin/praefect: No such file or directory
migrate failed
make: *** [_postgresql-seed-praefect] Error 1
```

This means `/gitaly/_build/bin/praefect` is missing. To re-create this executable file, run the following in your GDK directory:

```shell
make gitaly-update
```

## Updating the GDK

### Run `gdk doctor`

As a general rule, if you encouter errors when you run `gdk update`, you should run `gdk doctor` and follow the suggestions it
returns. They might resolve your issue.

### Error due to `Net::OpenTimeout: Failed to open TCP connection to rubygems.org:443`

When you run `gdk update` you might get an error like the following:

```plaintext
ERROR:  While executing gem ... (Gem::RemoteFetcher::FetchError)
```

This indicates that `bundle` failed to connect to the `rubygems.org` server.

If you are connected to the network and other network activities are working (i.e. `ping gitlab.com`), then this normally indicates
an outage of `rubygems.org`. You can try manually running `bundle update` in the GDK root folder, and if it fails with a similar
network error, you know this is the cause.

However, in some cases, even though `bundle update` is otherwise working successfully, you might get an error like the following:

```plaintext
INFO: Installing gitlab-development-kit Ruby gem..
ERROR:  While executing gem ... (Gem::RemoteFetcher::FetchError)
    Net::OpenTimeout: Failed to open TCP connection to rubygems.org:443 (execution expired) (https://rubygems.org/specs.4.8.gz)
```

This can happen if the IPv6 access to `rubygems.org` is having an outage, but IPv4 access is still working.

Using [this comment](https://github.com/rubygems/rubygems/pull/2662#issuecomment-779730989) as an example, you can add `:ipv4_fallback_enabled: true` to your `~/.gemrc`` to work around this until [this rubygems pull request](https://github.com/ruby/ruby/pull/4038) gets merged.

If that doens't work for some reason, you can alternately go into your operating system network settings and disable IPv6 for your network adapter. Refer to your
operating system documentation for detailed instructions.

## Starting the GDK

### Error due to `ActionController::InvalidAuthenticityToken`

If you encounter an `ActionController::InvalidAuthenticityToken` error when starting GDK, try the following steps:

- Hard refresh your browser to clear the cache. For more information, see [How to hard refresh your browser](https://fabricdigital.co.nz/blog/how-to-hard-refresh-your-browser-and-clear-cache).
- Stop all GDK processes using `gdk kill`, then restart GDK with `gdk start`.
- Delete all browser cache, cookies, local storage, and other related data for the relevant hostname.

### Error starting `timeout: down: /Users/foo/gdk/services/rails-background-jobs: 0s, want up`

Check if a background job process is unexpectedly running:

- Search for processes related to background jobs: `ps aux | grep rails-background-jobs`
- If runit is currently trying to start `rails-background-jobs` then you may find: `runsvdir -P /Users/foo/gdk/services log: atal: unable to lock supervise/lock: temporary failure\012runsv rails-background-jobs: fatal: unable to lock supervise/lock: temporary failure\012runsv rails-background-jobs: fatal: unable to lock supervise/lock: temporary failure\012runsv rails-background-jobs: fatal: unable to lock supervise/lock: temporary failure\012runsv rails-background-jobs: fatal: unable to lock supervise/lock: temporary failure\012`
- Stop GDK services: `gdk stop`
- If `ps aux | grep rails-background-jobs` shows that `runsv rails-background-jobs` is still running, then it is preventing `rails-background-jobs` from starting
- Kill the process by following [Stopping and restarting the GDK](#stopping-and-restarting-the-gdk)

If the above is not the problem, then confirm you can run `rails-background-jobs` manually: `RAILS_ENV=development ./bin/background_jobs start_foreground`.

## Stopping and restarting the GDK

Sometimes the GDK will fail to stop or restart. This is sometimes caused by processes not shutting down gracefully and can prevent subsequent attempts to stop/start the GDK.

You might see something like the following after running `gdk stop`:

```shell
kill: run: ./services/rails-background-jobs: (pid 89668) 98s, normally down, want down
```

To kill off the rogue processes, run `gdk kill`.

## Unable to log in as root

If all the services are running after you run `gdk install`, but you cannot log
in as `root`, you can reset the password through the Rails console.

For more information about the Ruby on Rails console in GitLab, see [Rails console](https://docs.gitlab.com/ee/administration/operations/rails_console.html).

1. Open a new Rails console:
    
    ```shell
    cd <gdk-dir>/gitlab
    bundle exec rails console
    ```

1. In the Rails console, update the password for the `root` user:

    ```ruby
    user = User.find_by_username('root')
    user.update!(password: 'newpassword')
    ```

To find the user IDs for all current users, run:

```ruby
User.all
```
