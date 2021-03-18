# Set up GitLab Docs

Our CI/CD pipelines include [some documentation checks](https://docs.gitlab.com/ee/development/documentation/index.html#testing)
for the documentation in GitLab. To run the links checks locally or preview the changes:

1. Add the following settings in your `gdk.yml`:

    ```yaml
    gitlab_docs:
      enabled: true
    ```

1. Run `gdk update`

1. Change directory:

   ```shell
   cd gitlab-docs/
   ```

1. (Optionally) Preview the docs site locally:

   ```shell
   bundle exec nanoc live -p 3005
   ```

   Visit <http://127.0.0.1:3005/ee/README.html>.

   If you see the following message, another process is already listening on port `3005`:

   ```shell
   Address already in use - bind(2) for 127.0.0.1:3005 (Errno::EADDRINUSE)`
   ```

   Select another port and try again.

## Check documentation links

If you've moved or renamed any sections within the documentation, to verify your
changes to internal links and anchors, either:

- Use your editor's "Follow Link" or "Go To Declaration/Usage/Implementation" function (or similar).
- Run the following:

  ```shell
  make gitlab-docs-check
  ```
