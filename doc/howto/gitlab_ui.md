# GitLab UI

If you wish to clone and keep an updated [GitLab UI](https://gitlab.com/gitlab-org/gitlab-ui/)
as part of your GDK, simply:

1. Add the following settings in your `gdk.yml`:

    ```yaml
    gitlab_ui:
      enabled: true
    ```

1. Run `gdk update`

## Testing local changes

[Link your local `@gitlab/ui` package to the GitLab project](https://gitlab.com/gitlab-org/gitlab-ui/-/blob/main/doc/contributing/gitlab_integration_test.md).
