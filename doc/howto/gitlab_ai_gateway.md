# GitLab AI Gateway

Below are the steps required to have the [GitLab AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist)
running locally which automates the 'Setup GitLab Development Kit (GDK)' step
listed in the [AI features local setup](https://docs.gitlab.com/ee/development/ai_features/index.html#local-setup) section:

1. `gdk config set gitlab_ai_gateway.enabled true`
1. `gdk update`
1. `gdk start gitlab-ai-gateway`
1. Visit the [GitLab AI Gateway API docs page](http://localhost:5052/docs) to view the API docs page

See the [AI features based on 3rd-party integrations](https://docs.gitlab.com/ee/development/ai_features/index.html) for more detail.
