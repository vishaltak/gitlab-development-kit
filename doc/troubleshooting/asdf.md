# Troubleshooting asdf

The following are possible solutions to problems you might encounter with [`asdf`](https://asdf-vm.com) and GDK.

## GDK update fails to find the `asdf` path

GDK update might fail at the "Updating asdf release, plugins, and tools" step

```plaintext
--------------------------------------------------------------------------------
Updating asdf release, plugins, and tools
--------------------------------------------------------------------------------
Unknown command: `asdf version`
/usr/local/Cellar/asdf/0.10.2/libexec/bin/asdf: line 82: /usr/local/Cellar/asdf/0.8.1_1/libexec/lib/commands/command-help.bash: No such file or directory
INFO: asdf installed using non-Git method. Attempt to update asdf skipped.
Unknown command: `asdf plugin-update --all`
/usr/local/Cellar/asdf/0.10.2/libexec/bin/asdf: line 82: /usr/local/Cellar/asdf/0.8.1_1/libexec/lib/commands/command-help.bash: No such file or directory
Unknown command: `asdf install`
/usr/local/Cellar/asdf/0.10.2/libexec/bin/asdf: line 82: /usr/local/Cellar/asdf/0.8.1_1/libexec/lib/commands/command-help.bash: No such file or directory

ERROR: Failed to update some asdf tools.
make[1]: *** [asdf-update-run] Error 1
make: *** [asdf-update-timed] Error 2
❌️ ERROR: Failed to update.
```

This happens when `asdf` is updated to a new version during the GDK update. The `asdf reshim` command not updating the `asdf`
path is a [known issue](https://github.com/asdf-vm/asdf/issues/531).

To fix this, you can run the following command:

```shell
rm -rf ~/.asdf/shims && asdf reshim
```

## Error: `command not found: gdk`

Access to the `gdk` command requires a properly configured Ruby installation. If the Ruby installation isn't properly
configured, your shell can't find the `gdk` command, and running commands like `gdk install` and `gdk start`
cause the following error:

```shell
command not found: gdk
```

A common cause of this error is an incomplete `asdf` setup. To determine if `asdf` setup is complete, run:

```shell
which asdf
```

If this command produces the error `asdf not found`, `asdf` set up isn't complete. This commonly occurs on GDK installations
on new workstations that have no custom shell configuration. A common solution to an `asdf` installation problem is to
follow the [Install `asdf`](https://asdf-vm.com/guide/getting-started.html#_3-install-asdf) instructions.

The required instructions depend on your operating system and method of installing `asdf`. For macOS, the most common
combination is:

- ZSH shell.
- Installation using Homebrew.
