# GitLab Duo Chat

Enable [GitLab Duo Chat](https://docs.gitlab.com/ee/user/gitlab_duo_chat.html) feature on your GDK for developments.

## Prerequisites 

1. GDK has already been installed and it's working.
1. Ultimate license is activated. See [this section](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/index.md#use-gitlab-enterprise-features) for more information.
1. Anthropic API key. You can request from [Access Request](https://about.gitlab.com/handbook/business-technology/end-user-services/onboarding-access-requests/access-requests/) (GitLab member only).
1. Access to a Google Cloud Project with Vertex AI enabled. See https://docs.gitlab.com/ee/development/ai_features/index.html#configure-gcp-vertex-access for more information.

## Installations

Configure GDK:

```shell
gdk config set gitlab_duo_chat.enabled true

# Set Anthropic API Key.
gdk config set gitlab_duo_chat.anthropic_api_key "<your-anthropic-key>"

# Set GOOGLE_APPLICATION_CREDENTIALS for Vertex API.
# See https://cloud.google.com/vertex-ai/docs/general/custom-service-account for creating a new service account,
# and https://cloud.google.com/iam/docs/keys-create-delete for creating API key.
gdk config set gitlab_duo_chat.google_application_credentials "<path-to-your-json-key>"

# Apply your configurations.
gdk reconfigure
```

Activate the feature in a GitLab group:

```shell
cd gitlab

# Activate the feature on the specified group path.
# Format: bin/rake gitlab:duo_chat:activate['<path-to-a-group>']
bin/rake gitlab:duo_chat:activate['gitlab-org']
```

Follow [this documentation](pgvector.md) to prepare a vector store for a similarity search in GitLab Documents.

## Further reading

See [Development guideline](https://docs.gitlab.com/ee/development/ai_features/index.html) for more information.
