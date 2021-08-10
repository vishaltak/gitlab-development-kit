---
stage: Ecosystem
group: Contributor Experience
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Shell completion

To enable tab completion for the `gdk` command in Bash, add the following to your `~/.bash_profile`:

```shell
source ~/path/to/your/gdk/support/completions/gdk.bash
```

For Zsh, you can enable Bash completion support in your `~/.zshrc`:

```shell
autoload bashcompinit
bashcompinit

source ~/path/to/your/gdk/support/completions/gdk.bash
```
