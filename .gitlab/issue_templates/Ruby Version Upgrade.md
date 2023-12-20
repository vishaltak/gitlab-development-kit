<!-- Replace `<RUBY_VERSION>` with the new Ruby version. -->

## Overview

The goal of this issue is to upgrade the Ruby version to `<RUBY_VERSION>`.

### Prior to Starting to Upgrade Ruby Version
  
- [ ] Confirm the new Ruby version is available in [asdf-ruby](https://github.com/asdf-vm/asdf-ruby).

### Checklist

- [ ] Update the version of Ruby in the `.tool-versions` file for the following projects:
  - [ ] gitaly
  - [ ] gitlab
  - [ ] gitlab-docs
  - [ ] gitlab-pages
  - [ ] gitlab-shell
  - [ ] gitlab-development-kit
- [ ] Update the version of Ruby in the [GDK E2E image](https://gitlab.com/gitlab-org/gitlab-build-images/-/blob/a1ed9f50ca0e8b8f5af221bf028cc82f02bc0748/.gitlab/ci/e2e.images.yml#L56).
- [ ] Update any dependencies or packages that may be affected by the version change.
- [ ] Test the GDK using the new Ruby version by running `verify-*` jobs in CI pipelines ensure the compatibility.
- [ ] Test the Gitpod GDK docker image using the new Ruby version by running `verify-gitpod-workspace-image` job in CI pipelines.
- [ ] Once the Ruby version has been upgraded, deploy a new Gitpod GDK docker image in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/60384.
- [ ] Notify team members of the upgrade by creating an announcement in the [`data/announcements`](https://gitlab.com/gitlab-org/gitlab-development-kit/-/tree/main/data/announcements) directory.

### Announcement

Once the upgrade is ready to take place, an announcement should be made in the `#gdk` Slack channel with a message using the following message as an example:

```
Hey team! Please be advised that an upgrade of the Ruby version to ________ is scheduled to take place on ________. If you experience any issues or have any concerns, please contact to us in this issue: ________. Thank you for your understanding.
```

/label ~"Category:GDK" ~"gdk-reliability" ~Quality ~"Engineering Productivity" ~"type::maintenance" ~"maintenance::dependency"

<!-- template sourced from https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/.gitlab/issue_templates/Ruby Version Upgrade.md -->
