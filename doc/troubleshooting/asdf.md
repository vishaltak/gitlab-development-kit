# Troubleshooting asdf

The following are possible solutions to problems you might encounter with asdf and GDK.

## GDK update fails to find the asdf path

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

This happens when `asdf` is updated to a new version during the GDK update. This a [known issue](https://github.com/asdf-vm/asdf/issues/531) that `asdf reshim` does not update the `asdf` path.

To fix this, you can run the following command:

```shell
rm -rf ~/.asdf/shims && asdf reshim
```
