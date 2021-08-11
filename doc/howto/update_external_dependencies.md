---
stage: Ecosystem
group: Contributor Experience
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Update external dependencies

As well as keeping GDK up to date, many of the underlying dependencies should also be regularly
updated. For example, to list dependencies that are outdated for macOS with `brew`, run:

```shell
brew update && brew outdated
```

Review the list of outdated dependencies. There may be dependencies you don't wish to upgrade. To
upgrade:

- All outdated dependencies for macOS with `brew`, run:

  ```shell
  brew update && brew upgrade
  ```

- Specific dependencies for macOS with `brew`, run:

  ```shell
  brew update && brew upgrade <package name>
  ```

We recommend you update GDK immediately after you update external dependencies.
