## What does this merge request do and why?

<!-- Briefly describe what this merge request does and why. -->

%{first_multiline_commit}

## How to set up and validate locally

_Numbered steps to set up and validate the change are strongly suggested._

<!--
Example below:

1. Ensure GitLab Pages is enabled by adding the below configuration in `gdk.yml`:
  ```yml
  ---
  gitlab_pages:
    enabled: true
  ```
1. Check out to this merge request's branch.
1. Run `gdk reconfigure` to check if regenerating all configuration is successful.
-->

## Impacted categories

The following categories relate to this merge request:

- [ ] ~"gdk-reliability" - e.g. When a GDK action fails to complete.
- [ ] ~"gdk-usability" - e.g. Improvements or suggestions around how the GDK functions.
- [ ] ~"gdk-performance" - e.g. When a GDK action is slow or times out.

<!-- Please add the selected labels to this merge request, thanks ♥️ -->

## Merge request checklist

- [ ] This change is backward compatible. If not, please include steps to communicate to our users.
- [ ] Tests added for new functionality. If not, please raise an issue to follow-up.
- [ ] Documentation added/updated, if needed.
- [ ] [Announcement added](doc/howto/announcements.md), if change is notable.
- [ ] `gdk doctor` test added, if needed.
- [ ] Add the `~highlight` label if this MR should be included in the [`CHANGELOG.md`](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/CHANGELOG.md).

/label ~"Category:GDK" ~Quality ~"Engineering Productivity" ~"type::feature" ~"feature::enhancement" 
/assign me

<!-- template sourced from https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/.gitlab/merge_request_templates/Default.md -->
