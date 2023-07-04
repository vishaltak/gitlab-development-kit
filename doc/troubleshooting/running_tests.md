# Troubleshooting running tests

There may be times when running spinach feature tests or Ruby Capybara RSpec
tests (tests that are located in the `spec/features` directory) fails.

## `pcre2.h` problems

`rspec` tests can fail with the error `'pcre2.h' file not found`. This error can occur on `arm64` macOS systems that
install `pcre2` with Homebrew.

By default, Homebrew installs packages for `arm64` under `/opt/homebrew` which causes issue for the Gitaly instance
that is built for running tests. To resolve the issue:

1. Remove the Gitaly instance that is built for running tests (it must be built again) at `<path-to-gdk>/gitlab/tmp/tests/gitaly`.
1. Set the `LIBPCREDIR` environment variable to `/opt/homebrew/opt/pcre2`, either:

   - Inline when running tests:

     ```shell
     LIBPCREDIR=/opt/homebrew/opt/pcre2 bundle exec rspec <path-to-test-file>
     ```

   - Permanently in your shell's configuration `export LIBPCREDIR="/opt/homebrew/opt/pcre2"`.

## ChromeDriver problems

ChromeDriver is the app on your machine that is used to run headless
browser tests.

If you see this error in your test output (you may need to scroll up): `Selenium::WebDriver::Error::SessionNotCreatedError`
coupled with the error message: `This version of ChromeDriver only supports Chrome version [...]`,
you need to update your version of ChromeDriver:

- If you installed ChromeDriver with Homebrew, then you can update by running:

  ```shell
  brew upgrade --cask chromedriver
  ```

- Otherwise you may need to [download and install](https://sites.google.com/chromium.org/driver)
  the latest ChromeDriver directly.

If ChromeDriver fails to open with an error message because the developer "cannot be verified",
create an exception for it as documented in the [macOS documentation](https://support.apple.com/en-gb/guide/mac-help/mh40616/mac).

## Database problems

Another issue can be that your test environment's database schema has
diverged from what the GitLab app expects. This can happen if you tested
a branch locally that changed the database in some way, and have now
switched back to `main` without
[rolling back](https://edgeguides.rubyonrails.org/active_record_migrations.html#rolling-back)
the migrations locally first.

In that case, what you need to do is run the following command inside
the `gitlab` directory to drop all tables on your test database and have
them recreated from the canonical version in `db/structure.sql`. Note,
dropping and recreating your test database tables is perfectly safe!

```shell
cd gitlab
bundle exec rake db:test:prepare
```

## Failures when generating Karma fixtures

In some cases, running `bin/rake karma:fixtures` might fail to generate some fixtures. You can see errors in the console like these:

```plaintext
Failed examples:

rspec ./spec/javascripts/fixtures/blob.rb:25 # Projects::BlobController (JavaScript fixtures) blob/show.html
rspec ./spec/javascripts/fixtures/branches.rb:24 # Projects::BranchesController (JavaScript fixtures) branches/new_branch.html
rspec ./spec/javascripts/fixtures/commit.rb:22 # Projects::CommitController (JavaScript fixtures) commit/show.html
```

To fix this, remove `tmp/tests/` in the `gitlab/` directory and regenerate the fixtures:

```shell
rm -rf tmp/tests/ && bin/rake karma:fixtures
```

## TaskFailedError while setting up Gitaly

If you receive the error below, ensure that you don't have
`GIT_TEMPLATE_DIR="$(overcommit --template-dir)"`
[configured](https://github.com/sds/overcommit#automatically-install-overcommit-hooks).

```plaintext
==> Setting up Gitaly...
rake aborted!
Gitlab::TaskFailedError: Cloning into 'tmp/tests/gitaly'...
This repository contains hooks installed by Overcommit, but the `overcommit` gem is not installed.
Install it with `gem install overcommit`.
```

## Content Security Policy problems

Sometimes feature specs fail when run locally, due to the hot module reload (HMR) server being disallowed by the Content Security Policy. Example error:

```shell
JSConsoleError:
  Unexpected browser console output:
  webpack-internal:///AjYE 15 Refused to connect to 'ws://gdk.test:3001/_hmr/' because it violates the following Content Security Policy directive: "connect-src 'self' ws://localhost localhost".
```

Another example error:  

```javascript
Uncaught runtime errors:

ERROR
Cannot read properties of null (reading 'addEventListener')
TypeError: Cannot read properties of null (reading 'addEventListener')
```

It occurs when the GitLab hostname differs from the hostname that is allowed in the Content Security Policy, for example if `hostname` has been configured in `gdk.yml`.

As a workaround:

1. Disable hot module reloading in the `gdk.yml` configuration before running feature specs:

   ```yaml
   webpack:
     live_reload: false
   ```

1. Run `gdk reconfigure`.

For more information, see [issue 1875](https://gitlab.com/gitlab-org/gitlab-development-kit/-/issues/1875).
