# Troubleshooting Ruby

The following are possible solutions to problems you might encounter with Ruby and GDK.

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
gem pristine charlock_holmes
```

Or for example `re2` on MacOS:

```shell
/Users/user/gitlab-development-kit/gitlab/lib/gitlab/untrusted_regexp.rb:25:  [BUG] Segmentation fault at 0x0000000000000000
ruby 2.6.6p146 (2020-03-31 revision 67876) [x86_64-darwin19]
```

In which case you would run:

```shell
gem pristine re2
```

## An error occurred while installing thrift (0.14.0)

The installation of the `thrift` v0.14.0 gem during `bundle install` can fail with the following error due to a [known bug](https://bugs.ruby-lang.org/issues/17865).

```plaintext
[SNIPPED]

current directory: /wrkdirs/usr/ports/devel/rubygem-thrift/work/stage/usr/local/lib/ruby/gems/2.7/gems/thrift-0.14.0/ext
make "DESTDIR="
compiling binary_protocol_accelerated.c
binary_protocol_accelerated.c:404:68: error: '(' and '{' tokens introducing statement expression appear in different macro expansion contexts [-Werror,-Wcompound-token-split-by-macro]
  VALUE thrift_binary_protocol_class = rb_const_get(thrift_module, rb_intern("BinaryProtocol"));
                                                                   ^~~~~~~~~~~~~~~~~~~~~~~~~~~
/usr/local/include/ruby-2.7/ruby/ruby.h:1847:23: note: expanded from macro 'rb_intern'
        __extension__ (RUBY_CONST_ID_CACHE((ID), (str))) : \
                      ^
binary_protocol_accelerated.c:404:68: note: '{' token is here
  VALUE thrift_binary_protocol_class = rb_const_get(thrift_module, rb_intern("BinaryProtocol"));
                                                                   ^~~~~~~~~~~~~~~~~~~~~~~~~~~
/usr/local/include/ruby-2.7/ruby/ruby.h:1847:24: note: expanded from macro 'rb_intern'
        __extension__ (RUBY_CONST_ID_CACHE((ID), (str))) : \
                       ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/usr/local/include/ruby-2.7/ruby/ruby.h:1832:5: note: expanded from macro 'RUBY_CONST_ID_CACHE'
    {                                                   \
    ^
```

As a workaround, you can set the following Bundler config:

```shell
bundle config build.thrift --with-cppflags="-Wno-error=compound-token-split-by-macro"
bundle install
```

Running `gem install thrift -v '0.14.0' --source 'https://rubygems.org'` won't work because
`gem` bypasses the Bundler config.

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

A solution on macOS is to re-install [Xcode Command Line Tools](https://apple.stackexchange.com/questions/93573/how-to-reinstall-xcode-command-line-tools).

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

In the above example, you see that the charlock_holmes gem fails to load
`libicui18n.52.1.dylib`. You can try fixing this by [re-installing
charlock_holmes](#rebuilding-gems-with-native-extensions).

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

## OpenSSL 3 breaks Ruby builds

Ubuntu 22.04 and Fedora 36 ship with OpenSSL 3.0, which causes Ruby builds and gem failures.
Ruby 2.7.x and 3.0.x [don't support OpenSSL 3](https://bugs.ruby-lang.org/issues/18658).

As a [workaround](https://github.com/rbenv/ruby-build/discussions/1940#discussioncomment-2663209),
you must compile and install OpenSSL 1.1.1:

1. Install the dependencies:

   ```shell
   ## Ubuntu 22.04
   sudo apt install build-essential checkinstall zlib1g-dev

   ## Fedora 36
   sudo dnf groupinstall "Development Tools"
   sudo dnf install perl-core zlib-devel
   ```

1. Download OpenSSL 1.1.1:

   ```shell
   OPENSSL_VERSION=openssl-1.1.1q
   cd ~/Downloads
   wget https://www.openssl.org/source/$OPENSSL_VERSION.tar.gz
   tar -xf $OPENSSL_VERSION.tar.gz
   ```

1. Compile OpenSSL 1.1.1:

   ```shell
   cd ~/Downloads/$OPENSSL_VERSION
   ./config --prefix=/opt/$OPENSSL_VERSION --openssldir=/opt/$OPENSSL_VERSION shared zlib
   make
   make test
   sudo make install
   ```

1. Link the system's certs to OpenSSL's 1.1.1 directory:

   ```shell
   sudo rm -rf /opt/$OPENSSL_VERSION/certs
   sudo ln -s /etc/ssl/certs /opt/$OPENSSL_VERSION
   ```

1. Add the following line to your `.bashrc` or `.zshrc`:

   ```plaintext
   export RUBY_CONFIGURE_OPTS="--with-openssl-dir=/opt/openssl-1.1.1q/"
   ```

1. Start a new shell for the environment variable to apply, or source your
   `.bashrc` or `.zshrc`:

   ```shell
   source ~/.bashrc
   source ~/.zshrc
   ```

1. Remove Ruby 2.7.5 with `asdf`:

   ```shell
   asdf uninstall ruby 2.7.5
   ```

1. Bootstrap GDK:

   ```shell
   rm <path/to/gdk>/.cache/.gdk_platform_setup
   rm <path/to/gdk>/.cache/.gdk_bootstrapped
   make bootstrap
   ```

1. Update GDK:

   ```shell
   gdk update
   ```
