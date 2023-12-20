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
❌️ ERROR: Failed to update.
```

This happens when `asdf` is updated to a new version during the GDK update. The `asdf reshim` command not updating the `asdf`
path is a [known issue](https://github.com/asdf-vm/asdf/issues/531).

To fix this, you can run the following command:

```shell
rm -rf ~/.asdf/shims && asdf reshim
```

## GDK update fails with `No preset version installed for command` error

GDK update might fail if `asdf` cannot locate a software version that is already installed.

```shell
No preset version installed for command go
Please install a version by running one of the following:

asdf install golang 1.21.2

or add one of the following versions in your config file at /Users/foo/gitlab-development-kit/gitlab/workhorse/.tool-versions
golang 1.20.10
golang 1.20.9
golang 1.21.3
make[2]: *** [gitlab-resize-image] Error 126
make[1]: *** [gitlab/workhorse/gitlab-workhorse] Error 2
make: *** [gitlab-workhorse-update-timed] Error 2
❌️ ERROR: Failed to update.
```

To resolve this, you can run the following command to uninstall and reinstall the version:

```shell
asdf uninstall golang 1.21.2 && asdf install golang 1.21.2
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

### If `which asdf` returns  `asdf not found`

Then the `asdf` setup isn't complete. This often happens when installing GDK on new workstations without a custom shell configuration. 

A common solution is to follow the [`asdf` install instructions](https://asdf-vm.com/guide/getting-started.html#_3-install-asdf) for your operating system and preferred method of installing `asdf`. 

- For macOS, it's common to use `Zsh shell & Git` or `Zsh shell & Homebrew` if you prefer to use [homebrew](https://brew.sh/) for managing your packages.
- You can use `echo $SHELL` to check which shell your workstation's using.

### If you know `asdf` is installed

Then it's likely `asdf` isn't sourced properly. Try these troubleshooting ideas:

- Close and open a new shell.
- If you're on a new workstation, confirm you have a shell configuration file. 
  - On MacOS it's a hidden file located in your home directory. Navigate to your home folder with `cd ~` (or `⇧⌘H` in the finder) and then reveal hidden files with `ls -a` (or `⇧⌘.` in the finder). 
  - If you don't see a shell config file (e.g. `.zshrc`) you can create one (e.g `touch .zshrc`) and then redo the above `asdf` install instructions.
- Confirm your shell config file matches the [`asdf` instructions](https://asdf-vm.com/guide/getting-started.html#_3-install-asdf) for your chosen shell and install method.
  - For example, if you're using MacOS with Zsh and Homebrew then you could source `asdf` by adding `. /opt/homebrew/opt/asdf/libexec/asdf.sh` in the `.zshrc` file.
  - Double check your shell config file has the correct sourcing command. Some `asdf` instructions give you commands to copy and paste into the config file, while others are added indirectly after you run the command in your terminal. For example, in the `Zsh & Homebrew` instructions `echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ${ZDOTDIR:-~}/.zshrc` should be run by you in your terminal and not copy and pasted into `.zshrc`.
