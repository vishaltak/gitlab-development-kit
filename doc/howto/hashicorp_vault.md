# Using Hashicorp Vault with GDK

The `secrets` keyword in `.gitlab-ci.yml` allows users of GitLab CI/CD to fetch secrets from a Hashicorp Vault. Testing
changes to the `secrets` keyword requires a locally running instance of a Vault development server.

GDK can set up and maintain a Vault server for you.

## Installing Vault

Vault is installed with the other Homebrew packages in GDK's `Brewfile`.

## Enabling Vault

The Vault server is disabled by default. Enable it by adding this configuration to your `gdk.yml`:

```yaml
vault:
  enabled: true
```

Then run `gdk reconfigure`.

### Custom `listen_address`

By default, Vault runs on port `8200` at the same address as your GDK. If you want it to run at a different address,
you can configure it with `listen_address`:

```yaml
vault:
  enabled: true
  listen_address: 192.68.12.1 # Vault will always run on port 8200
```

### CI JWT signing key

You must have a CI JWT signing key to create JWTs to access Vault. Use the Rails console
to verify that you have one with:

```ruby
Gitlab::CurrentSettings.ci_jwt_signing_key  # An RSA private key
```

If `ci_jwt_signing_key` is `nil`, create a signing key with:

```ruby
ApplicationSetting.current_without_cache.update!(ci_jwt_signing_key: OpenSSL::PKey::RSA.new(2048).to_pem)
```

Then run `gdk reconfigure`.

## Configuring Vault

To quickly test the `secrets` keyword, set up all the test data you need by running the `vault:configure` Rake task
You must have both Vault and GDK running, and the `<project_id>` must match a project in your GDK:

```shell
bundle exec rake vault:configure[<project_id>]
```

**You must re-run this Rake task every time you restart the Vault service. The configuration does not persist.**

In the project matching the ID you gave to the Rake task, you can fetch a test secret using this CI job:

```yaml
test_secrets:
  variables:
    VAULT_AUTH_PATH: gitlab
    VAULT_AUTH_ROLE: gitlab-test-role
    VAULT_SERVER_URL: http://<vault_ip_address>:8200
  secrets:
    TEST_ID_TOKEN:
      id_token:
        aud: <gdk_address>  # For example: https://gdk.test:3443
    DATABASE_PASSWORD:
      vault: gitlab-test/db/password
  script:
    - echo $DATABASE_PASSWORD
    - cat $DATABASE_PASSWORD
```

You must replace `<vault_ip_address>`, `<gdk_address>`, and `<gdk_port>` with the real values.

### ID tokens

To use `secrets` with `id_tokens`, use the Rails console to enable `opt_in_jwt` for
the project:

```ruby
Project.find(<project_id>).ci_cd_settings.update!(opt_in_jwt: true)
```

## The `vault:configure` Rake task

This section explains in detail how the `vault:configure` Rake task works. This information
might be useful if you run into problems or want to do more complex testing.

The Rake task has many steps that execute in the following order.

### 1. Export the Vault address

`vault:configure` runs commands from the Vault CLI. To communicate with the Vault server,
the CLI checks the `VAULT_ADDR` variable. To set this value yourself, run:

```shell
export VAULT_ADDR='http://192.68.12.1:8200'
```

### 2. Enable the `kv-v2` secrets engine

Vault can store secrets in many different formats. The `secrets` keyword expects Vault to use the [kv-v2](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2)
engine. This engine is not enabled by default, and must be enabled using:

```shell
vault secrets enable -path=kv-v2 kv-v2
```

The `path` parameter must have the value `kv-v2` because that value is automatically prepended to Vault paths set with
the `vault` keyword.

### 3. Create a test secret

Created test secrets with:

```shell
vault kv put kv-v2/gitlab-test/db password=db-password-goes-here
```

`kv` creates a secret compatible with the `kv-v2` engine. The path can have any value, but it must be nested under
`kv-v2`. It is common to use the path to group secrets by environment (`gitlab-test`) and context (`db`).

### 4. Create an access policy

Vault needs an access policy that controls what your project can access. The `vault:configure` task runs:

```shell
vault policy write gitlab-test-policy - <<EOF
path "kv-v2/data/gitlab-test/*" {
  capabilities = [ "read" ]
}
EOF
```

Access roles that use this policy have read access to secrets nested under `kv-v2/data/gitlab-test`. The
`data` component of the path is automatically created by Vault. You don't need to specify the `data` when creating and
fetching secrets, but it must be specified when defining access policies.

### 5. Enable JWT authentication

GitLab uses JWTs to authenticate with Vault. JWT authentication is disabled by default and must be enabled with:

```shell
vault auth enable -path=gitlab jwt
```

The `path` parameter can have any value, but it must match a `VAULT_AUTH_PATH` variable in your CI/CD job configuration.

JWT authentication must be configured to allow requests from the GDK's address to access it:

```shell
vault write auth/gitlab/config \
    jwks_url="<gdk_url>/-/jwks" \
    bound_issuer="<gdk_url>"
```

### 6. Create an access role

The final step is to create an access role. Vault needs an access role that uses the `gitlab-test-policy`. This policy
is configured to allow a specific project to access secrets under the path configured in the policy. CI jobs in other
projects that try to access those secrets are denied.

```shell
vault write auth/gitlab/role/gitlab-test-role - <<EOF
{
  "role_type": "jwt",
  "policies": ["gitlab-test-policy"],
  "token_explicit_max_ttl": 600,
  "user_claim": "user_email",
  "bound_claims": {
    "project_id": "<project_id>"
  },
  "bound_audiences": "<gdk_url>"
}
EOF
```

## Troubleshooting

If you see this error:

```plaintext
ERROR: Job failed (system failure): resolving secrets: initializing Vault service: preparing authenticated client:
authenticating Vault client: writing to Vault: api error: status code 403: permission denied
```

Verify you ran the [`vault:configure` Rake task](#configuring-vault) after you last started Vault,
and used the correct project ID.
