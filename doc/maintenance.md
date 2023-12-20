# GDK maintenance

[[_TOC_]]

## Accessing CI/CD variables

Project CI/CD variables are set in <https://gitlab.com/gitlab-org/gitlab-development-kit/-/settings/ci_cd>. All users with the Maintainer role
on this project can access them.

Group CI/CD variables are set in the [`gitlab-org` group](https://gitlab.com/gitlab-org), and only users with the Maintainer role on that group
can access them.

## Rotate the `GITLAB_LICENSE_KEY` variable

1. Request a new license to store in the variable. For more information, see
   [Working on GitLab EE (developer licenses)](https://about.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee-developer-licenses).
1. Update `GITLAB_LICENSE_KEY` variable at [GDK CI/CD Settings](https://gitlab.com/gitlab-org/gitlab-development-kit/-/settings/ci_cd).
1. Contact the Support Team to revoke the existing license.
