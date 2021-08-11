---
stage: Ecosystem
group: Contributor Experience
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Mattermost

From the GDK directory, create [a `gdk.yml` configuration file](../configuration.md)
containing the following settings:

```yaml
mattermost:
  enabled: true
```

Then you just have to re-generate your Procfile by reconfiguring:

```shell
gdk reconfigure
```
