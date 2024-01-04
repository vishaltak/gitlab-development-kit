# Improving dependency management performance with `mise`

[`mise`](https://github.com/jdx/mise) is a dependency manager that works as a drop-in replacement to `asdf`.
The benefits are:

- Written in Rust instead of shell scripts, which means that it is orders of magnitude faster than `asdf` when invoking
  commands (20x-200x faster).
- No need for shims, so the `which` command points to the right path.
- `asdf`-compatible: `mise` is compatible with `asdf` plugins and `.tool-versions` files.
  It can be used as a drop-in replacement.
- [More benefits](https://mise.jdx.dev/comparison-to-asdf.html) in the `mise` documentation.

To move from `asdf` to `mise`, follow these steps (assuming that `$GDK_ROOT` points to the directory where the GDK is
installed in):

1. Opt out of `asdf` in `$GDK_ROOT/gdk.yml`:

   ```shell
   gdk config set asdf.opt_out true
   ```

1. Create local `lefthook` hooks to ensure that `mise` gets a chance to install the current versions of dependencies:

   ```shell
   cat << EOF >> $GDK_ROOT/lefthook-local.yml
   # For git pulls
   post-merge:
     follow: true
     commands:
       mise-install:
         run: mise plugins update ruby; mise install

   # When switching branches
   post-checkout:
     follow: true
     commands:
       mise-install:
         run: mise plugins update ruby; mise install
   EOF
   ```

1. Install the new local hooks:

   ```shell
   (cd $GDK_ROOT && lefthook install)
   ```

1. Remove `asdf` from your shell configuration and [install `mise`](https://mise.jdx.dev/faq.html#how-do-i-migrate-from-asdf):

   ```shell
   brew install mise
   eval "$(mise activate $SHELL)"
   eval "$(mise hook-env)"
   ```

1. Install the current dependencies in the `mise` cache:

   ```shell
   (cd $GDK_ROOT/gitlab && mise install --install-missing)
   ```

1. Reconfigure and update the GDK. This time, `mise` is used to install the dependencies and `asdf` is not required
   anymore.

   ```shell
   (cd $GDK_ROOT && gdk reconfigure && gdk update)
   ```

1. (Optional) [Uninstall asdf](https://asdf-vm.com/manage/core.html#uninstall).
