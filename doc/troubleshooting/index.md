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

For more information about Jaeger, visit the [distributed tracing GitLab developer
documentation](https://docs.gitlab.com/ee/development/distributed_tracing.html).

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
instructions for [Ubuntu/Debian](../index.md#ubuntudebian) or [Arch/Manjaro](../index.md#arch-and-manjaro-linux). If
that doesn't give you the supported version, you might have to [compile Git from source](https://docs.gitlab.com/ee/install/installation.html#git).

### `your socket path is likely too long, please change Gitaly's runtime directory`

If you see the following error when running `rspec`:

```shell
RuntimeError:
  gitaly spawn failed

  Check log/gitaly-test.log & log/praefect-test.log for errors.
```

If you find the error message above within the test log, the GDK path is too long. socket paths are
limited to 104 (macOS) or 108 (Linux) characters. Move or reinstall GDK to a shorter path on your
development machine.

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

## Stopping and restarting the GDK

Sometimes the GDK will fail to stop or restart. This is sometimes caused by processes not shutting down gracefully and can prevent subsequent attempts to stop/start the GDK.

You might see something like the following after running `gdk stop`:

```shell
kill: run: ./services/rails-background-jobs: (pid 89668) 98s, normally down, want down
```

To kill off the rogue processes, run `gdk kill`.
