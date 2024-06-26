# Troubleshooting Ruby

The following are possible solutions to problems you might encounter with Ruby and GDK.

## GDK command not found error

If you receive an error that the `gdk` command can't be found, it's often because of either:

- An environment issue. The Ruby environment that GDK was installed with is no longer available. For most people, this is because `asdf` is no longer
  properly configured. To check if your Ruby is currently managed by `asdf`, run:

  ```shell
  which ruby
  ```

  For most people, this command returns `/Users/<name>/.asdf/shims/ruby`. If this command returns something else and you haven't set up your own
  Ruby environment, follow the [Install `asdf`](https://asdf-vm.com/guide/getting-started.html#_3-install-asdf) instructions to reconfigure `asdf`.

- A missing gem issue. The Ruby environment is correctly configured but the `gitlab-development-kit` gem is no longer installed. To restore the
  `gitlab-development-kit` gem that provides the `gdk` command, run:

   ```shell
   gem install gitlab-development-kit
   ```

## Rebuilding gems with native extensions

There may be times when local libraries that are used to build some gems'
native extensions are updated (for example, `libicu`), thus resulting in errors like:

```shell
rails-background-jobs.1 | /home/user/.rvm/gems/ruby-2.3.0/gems/activesupport-4.2.5.2/lib/active_support/dependencies.rb:274:in 'require': libicudata.so
cannot open shared object file: No such file or directory - /home/user/.rvm/gems/ruby-2.3.0/gems/charlock_holmes-0.7.3/lib/charlock_holmes/charlock_holmes.so (LoadError)
```

```shell
cd /home/user/gitlab-development-kit/gitlab && bundle exec rake gettext:compile > /home/user/gitlab-development-kit/gitlab/log/gettext.log 2>&1
make: *** [.gettext] Error 1
```

```shell
rake aborted!
LoadError: dlopen(/home/user/.rbenv/versions/2.6.3/lib/ruby/gems/2.5.0/gems/charlock_holmes-0.7.6/lib/charlock_holmes/charlock_holmes.bundle, 9): Library not loaded: /usr/local/opt/icu4c/lib/libicudata.63.1.dylib
  Referenced from: /home/user/.rbenv/versions/2.6.3/lib/ruby/gems/2.5.0/gems/charlock_holmes-0.7.6/lib/charlock_holmes/charlock_holmes.bundle
  Reason: image not found - /home/user/.rbenv/versions/2.6.3/lib/ruby/gems/2.5.0/gems/charlock_holmes-0.7.6/lib/charlock_holmes/charlock_holmes.bundle
```

In that case, find the offending gem and use `pristine` to rebuild its native
extensions:

```shell
bundle pristine charlock_holmes
```

Or for example `re2` on MacOS:

```shell
/Users/user/gitlab-development-kit/gitlab/lib/gitlab/untrusted_regexp.rb:25:  [BUG] Segmentation fault at 0x0000000000000000
ruby 2.6.6p146 (2020-03-31 revision 67876) [x86_64-darwin19]
```

In which case you would run:

```shell
bundle pristine re2
```

## An error occurred while installing thrift

The installation of the `thrift v0.16.0` gem during `bundle install` can fail with the following error because `clang <= 13` [does not properly handle `__has_declspec()`](https://github.com/ruby/ruby/commit/0958e19ffb047781fe1506760c7cbd8d7fe74e57):

```plaintext
[SNIPPED]

current directory: /path/to/.asdf/installs/ruby/3.1.4/lib/ruby/gems/3.1.0/gems/thrift-0.16.0/ext
/path/to/.asdf/installs/ruby/3.1.4/bin/ruby -I /path/to/.asdf/installs/ruby/3.1.4/lib/ruby/3.1.0 extconf.rb
checking for strlcpy() in string.h... *** extconf.rb failed ***
Could not create Makefile due to some reason, probably lack of necessary
libraries and/or headers.  Check the mkmf.log file for more details.  You may
need configuration options.

[SNIPPED]

To see why this extension failed to compile, please check the mkmf.log which can be found here:

 /path/to/.asdf/installs/ruby/3.1.4/lib/ruby/gems/3.1.0/extensions/x86_64-darwin-19/3.1.0/thrift-0.16.0/mkmf.log

[SNIPPED]

An error occurred while installing thrift (0.16.0), and Bundler cannot continue.

In Gemfile:
  gitlab-labkit was resolved to 0.32.0, which depends on
    jaeger-client was resolved to 1.1.0, which depends on
      thrift
```

Contents of `mkmf.log`:

```plaintext
[SNIPPED]

/path/to/.asdf/installs/ruby/3.1.4/include/ruby-3.1.0/ruby/assert.h:132:1: error: '__declspec' attributes are not enabled; use '-fdeclspec' or '-fms-extensions' to enable support for __declspec attributes
RBIMPL_ATTR_NORETURN()
^
/path/to/.asdf/installs/ruby/3.1.4/include/ruby-3.1.0/ruby/internal/attr/noreturn.h:29:33: note: expanded from macro 'RBIMPL_ATTR_NORETURN'
# define RBIMPL_ATTR_NORETURN() __declspec(noreturn)

[SNIPPED]

/path/to/.asdf/installs/ruby/3.1.4/include/ruby-3.1.0/ruby/internal/core/rbasic.h:63:14: error: expected parameter declarator
RUBY_ALIGNAS(SIZEOF_VALUE)
             ^
/path/to/.asdf/installs/ruby/3.1.4/include/ruby-3.1.0/ruby/internal/value.h:106:23: note: expanded from macro 'SIZEOF_VALUE'
# define SIZEOF_VALUE SIZEOF_LONG

[SNIPPED]
```

To work around this issue, either:

- Set the `-fdeclspec` flag and run `gem install` manually:

  ```shell
  gem install thrift -v 0.16.0 -- --with-cppflags='-fdeclspec'
  ```

- Upgrade to the latest version of Xcode or manually upgrade to `clang >= 14`. For example:

  ```shell
  brew install llvm@14
  echo 'export PATH="/usr/local/opt/llvm@14/bin:$PATH"' >> ~/.zshrc
  gem install thrift -v 0.16.0
  ```

## An error occurred while installing `gpgme` on macOS

Check if you have `gawk` installed >= 5.0.0 and uninstall it.

Re-run the `gdk install` again and follow any on-screen instructions related to installing `gpgme`.

## `gem install gpgme` `2.0.x` fails to compile native extension on macOS Mojave

If building `gpgme` gem fails with an `Undefined symbols for architecture x86_64` error on macOS Mojave, build `gpgme` using system libraries instead.

1. Ensure necessary dependencies are installed:

   ```shell
   brew install gpgme
   ```

1. (optional) Try building the `gpgme` gem manually to ensure it compiles. If it fails, debug the failure with the error messages. To compile the `gpgme` gem manually run:

   ```shell
   gem install gpgme -- --use-system-libraries
   ```

1. Configure Bundler to use system libraries for the `gpgme` gem:

   ```shell
   bundle config build.gpgme --use-system-libraries
   ```

You can now run `gdk install` or `bundle` again.

## FFI gem issues

The following are problems you might encounter when installing the
[FFI gem](https://github.com/ffi/ffi/wiki) with possible solutions.

## `gem install ffi` fails with '`ffi.h` file not found'

If you see the following error installing the `ffi` gem via `gdk install`:

```shell
Gem::Ext::BuildError: ERROR: Failed to build gem native extension.
...
sed: 1: "s?\@XML_LIBDIR\@?-L/Use ...": bad flag in substitute command: '/'
...
*** extconf.rb failed ***
Could not create Makefile due to some reason, probably lack of necessary
libraries and/or headers.  Check the mkmf.log file for more details.  You may
need configuration options.
...
An error occurred while installing nokogiri (1.10.4), and Bundler cannot continue.
Make sure that `gem install nokogiri -v '1.10.4' --source 'https://rubygems.org/'` succeeds before bundling.
...
compiling AbstractMemory.c
In file included from AbstractMemory.c:47:
In file included from ./AbstractMemory.h:42:
./Types.h:78:10: fatal error: 'ffi.h' file not found
#include <ffi.h>
        ^~~~~~~
1 error generated.
make[1]: *** [AbstractMemory.o] Error 1
...
An error occurred while installing ffi (1.11.1), and Bundler cannot continue.
Make sure that `gem install ffi -v '1.11.1' --source 'https://rubygems.org/'` succeeds before bundling.
```

A solution on macOS is to:

1. Ensure the `PKG_CONFIG_PATH` and `LDFLAGS` environment variables are correctly set:

   ```shell
   export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$(brew --prefix)/opt/libffi/lib/pkgconfig"
   export LDFLAGS="$LDFLAGS:-L$(brew --prefix)/opt/libffi/lib"
   ```

1. Re-run `gdk install`

## `gem install ffi` fails with 'error: implicit declaration of function'

```shell
Installing ffi 1.13.1 with native extensions
Gem::Ext::BuildError: ERROR: Failed to build gem native extension.

current directory:
/Users/gdk/.rbenv/versions/2.6.6/lib/ruby/gems/2.6.0/gems/ffi-1.13.1/ext/ffi_c
-- snip --
compiling Function.c
Function.c:852:17: error: implicit declaration of function
'ffi_prep_closure_loc' is invalid in C99
[-Werror,-Wimplicit-function-declaration]
ffiStatus = ffi_prep_closure_loc(code, &fnInfo->ffi_cif, callback_invoke,
closure, code);
                ^
Function.c:852:17: note: did you mean 'ffi_prep_closure'?
/Library/Developer/CommandLineTools/SDKs/MacOSX10.14.sdk/usr/include/ffi/ffi.h:269:1:
note: 'ffi_prep_closure' declared here
ffi_prep_closure(
^
1 error generated.
make[2]: *** [Function.o] Error 1

make failed, exit code 2

Gem files will remain installed in
/Users/gdk/.rbenv/versions/2.6.6/lib/ruby/gems/2.6.0/gems/ffi-1.13.1 for
inspection.
Results logged to
/Users/gdk/.rbenv/versions/2.6.6/lib/ruby/gems/2.6.0/extensions/x86_64-darwin-18/2.6.0/ffi-1.13.1/gem_make.out

An error occurred while installing ffi (1.13.1), and Bundler cannot continue.
Make sure that `gem install ffi -v '1.13.1' --source 'https://rubygems.org/'`
succeeds before bundling.

In Gemfile:
  rbtrace was resolved to 0.4.14, which depends on
    ffi
make[1]: *** [/Users/gdk/code/ee-gdk/gitaly/.ruby-bundle] Error 5
make: *** [gitaly/bin/gitaly] Error 2
```

This error happens because macOS 10.14 [ships with an old version of the ffi library](https://github.com/ffi/ffi/issues/791#issuecomment-645594873),
which is not compatible with recent versions of the `ffi` gem. You
need to upgrade macOS and [XCode](https://apple.stackexchange.com/questions/93573/how-to-reinstall-xcode-command-line-tools).

Another workaround is to disable the system `ffi` library when installing the gem:

```shell
gem install ffi -- --disable-system-libffi
```

## LoadError due to readline

On macOS, GitLab may fail to start and fail with an error message about
`libreadline`:

```plaintext
LoadError:
    dlopen(/Users/gdk/.rbenv/versions/2.6.3/lib/ruby/2.5.0/x86_64-darwin15/readline.bundle, 9): Library not loaded: /usr/local/opt/readline/lib/libreadline.7.dylib
        Referenced from: /Users/gdk/.rbenv/versions/2.6.3/lib/ruby/2.5.0/x86_64-darwin15/readline.bundle
        Reason: image not found - /Users/gdk/.rbenv/versions/2.6.3/lib/ruby/2.5.0/x86_64-darwin15/readline.bundle
```

This happens because the Ruby interpreter was linked with a version of
the `readline` library that may have been updated on your system. To fix
the error, reinstall the Ruby interpreter. For example, for environments
managed with:

- [rbenv](https://github.com/rbenv/rbenv), run `rbenv install 2.7.2`.
- [RVM](https://rvm.io), run `rvm reinstall ruby-2.7.2`.

## 'LoadError: dlopen' when starting Ruby apps

This can happen when you try to load a Ruby gem with native extensions that
were linked against a system library that is no longer there. A typical culprit
is Homebrew on macOS, which encourages frequent updates (`brew update && brew
upgrade`) which may break binary compatibility.

```shell
bundle exec rake db:create dev:setup
rake aborted!
LoadError: dlopen(/Users/gdk/.rbenv/versions/2.1.2/lib/ruby/gems/2.1.0/extensions/x86_64-darwin-13/2.1.0-static/charlock_holmes-0.6.9.4/charlock_holmes/charlock_holmes.bundle, 9): Library not loaded: /usr/local/opt/icu4c/lib/libicui18n.52.1.dylib
  Referenced from: /Users/gdk/.rbenv/versions/2.1.2/lib/ruby/gems/2.1.0/extensions/x86_64-darwin-13/2.1.0-static/charlock_holmes-0.6.9.4/charlock_holmes/charlock_holmes.bundle
  Reason: image not found - /Users/gdk/.rbenv/versions/2.1.2/lib/ruby/gems/2.1.0/extensions/x86_64-darwin-13/2.1.0-static/charlock_holmes-0.6.9.4/charlock_holmes/charlock_holmes.bundle
/Users/gdk/gitlab-development-kit/gitlab/config/application.rb:6:in `<top (required)>'
/Users/gdk/gitlab-development-kit/gitlab/Rakefile:5:in `require'
/Users/gdk/gitlab-development-kit/gitlab/Rakefile:5:in `<top (required)>'
(See full trace by running task with --trace)
```

In the above example, you see that the `charlock_holmes` gem fails to load `libicui18n.52.1.dylib`. You can try fixing
this by [re-installing `charlock_holmes`](#rebuilding-gems-with-native-extensions).

## 'bundle install' fails due to permission problems

This can happen if you are using a system-wide Ruby installation. You can
override the Ruby gem install path with `BUNDLE_PATH`:

```shell
# Install gems in (current directory)/vendor/bundle
make BUNDLE_PATH=$(pwd)/vendor/bundle
```

## Bootsnap-related problems

If your local instance does not start up and you see `bootsnap` errors like this:

```plaintext
2020-07-09_07:29:27.20103 rails-web             : .rvm/gems/ruby-2.6.6/gems/bootsnap-1.4.6/lib/bootsnap/load_path_cache/core_ext/active_support.rb:61:in `block in load_missing_constant': uninitialized constant EE::OperationsHelper (NameError)
2020-07-09_07:29:27.20104 rails-web             : .rvm/gems/ruby-2.6.6/gems/bootsnap-1.4.6/lib/bootsnap/load_path_cache/core_ext/active_support.rb:17:in `allow_bootsnap_retry'
```

You should remove the `bootsnap` cache:

```shell
gdk stop
rm -rf gitlab/tmp/cache/bootsnap-*
gdk start
```

## Truncate Rails logs

The logs in `gitlab/log` keep growing forever as you use the GDK.

You can truncate them either manually with the provided Rake task:

```shell
rake gitlab:truncate_logs
```

Or add a [GDK hook](../configuration.md#hooks) to your `gdk.yml` with the following to truncate them
before every `gdk update`:

```yaml
gdk:
  update_hooks:
    before:
      - rake gitlab:truncate_logs
```

## Disabled System Integrity Protection (SIP) breaks Ruby builds on macOS

If SIP is disabled, the build fails when installing the `rbs-2.7.0` gem.

```plaintext
....
rbs 2.7.0
Building native extensions. This could take a while...
/private/var/folders/rd/h6s2crs17xv0btgdvxc020sr0000gr/T/ruby-build.20230823184744.71172.TjwoSj/ruby-3.1.4/lib/rubygems/ext/builder.rb:95:in `run': ERROR: Failed to build gem native extension. (Gem::Ext::BuildError)
```

The solution is to enable SIP using the
[official instructions](https://developer.apple.com/documentation/security/disabling_and_enabling_system_integrity_protection).

## `bundle install` returns `LoadError`

When you run `bundle install`, you might encounter the following error:

```shell
/Users/<username>/.asdf/installs/ruby/3.1.4/bin/bundle:25:in `load': cannot load such file -- /Users/<username>/.asdf/installs/ruby/3.1.4/lib/ruby/gems/3.1.0/gems/bundler-2.4.20/exe/bundle (LoadError) from /Users/<username>/.asdf/installs/ruby/3.1.4/bin/bundle:25:in `<main>'
```

To resolve this issue, run the following command to update the bundler:

```shell
gem install bundler
```
