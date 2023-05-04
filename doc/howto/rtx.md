# Improving dependency management performance with `rtx`

[`rtx`](https://github.com/jdxcode/rtx) is a dependency manager that works as a drop-in replacement to `asdf`.
The benefits are:

- Written in Rust instead of shell scripts, which means that it is orders of magnitude faster than `asdf` when invoking
  commands (20x-200x faster).
- No need for shims, so the `which` command points to the right path.
- `asdf`-compatible: `rtx` is compatible with `asdf` plugins and `.tool-versions` files.
  It can be used as a drop-in replacement.
- [More benefits](https://github.com/jdxcode/rtx#features) in the `rtx` repository.

To move from `asdf` to `rtx`, follow these steps (assuming that `$GDK_ROOT` points to the directory where the GDK is
installed in):

1. Opt out of `asdf` in `$GDK_ROOT/gdk.yml`:

   ```shell
   gdk config set asdf.opt_out true
   ```

1. Create local `lefthook` hooks to ensure that `rtx` gets a chance to install the current versions of dependencies:

   ```shell
   cat << EOF >> $GDK_ROOT/lefthook-local.yml
   # For git pulls
   post-merge:
     follow: true
     commands:
       rtx-install:
         run: rtx plugins update ruby; rtx install

   # When switching branches
   post-checkout:
     follow: true
     commands:
       rtx-install:
         run: rtx plugins update ruby; rtx install
   EOF
   ```

1. Install the new local hooks:

   ```shell
   (cd $GDK_ROOT && lefthook install)
   ```

1. Remove `asdf` from your shell configuration and [install `rtx`](https://github.com/jdxcode/rtx#how-do-i-migrate-from-asdf):

   ```shell
   brew install rtx
   eval "$(rtx activate $SHELL)"
   eval "$(rtx hook-env)"
   ```

1. Install the current dependencies in the `rtx` cache:

   ```shell
   (cd $GDK_ROOT/gitlab && rtx install --install-missing)
   ```

1. Reconfigure and update the GDK. This time, `rtx` is used to install the dependencies and `asdf` is not required
   anymore.

   ```shell
   (cd $GDK_ROOT && gdk reconfigure && gdk update)
   ```

1. (Optional) [Uninstall asdf](https://asdf-vm.com/manage/core.html#uninstall).
