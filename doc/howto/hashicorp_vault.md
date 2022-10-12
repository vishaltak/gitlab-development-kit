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

Then run `gdk reconfigure`.

## Using the Vault CLI

You can interact with Vault using the Vault CLI. First set `VAULT_ADDR` to the address Vault is configured at:

```shell
export VAULT_ADDR='http://192.68.12.1:8200'
```

Create a new Vault that uses the `kv-v2` engine. This engine is used by the `secrets` keyword:

```shell
vault secrets enable -path=kv-v2 kv-v2
```

Create a secret:

```shell
vault kv put kv-v2/gitlab-test/db password=db-password-goes-here
```

Create an authentication policy:

```shell
vault policy write gitlab-test-policy - <<EOF
path "kv-v2/data/gitlab-test/*" {
  capabilities = [ "read" ]
}
EOF
```

Create an authentication role. In the below script, make the following replacements:

- Replace `<project_id>` with a project ID from a project present on your GDK. Only that project is able to authenticate
   with your Vault
- Replace `<gdk_url>` with the full URL of your GDK, including port and `http` or `https`. Ex: `https://gdk.test:3443`

```shell
vault auth enable -path=gitlab jwt

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

vault write auth/gitlab/config \
    jwks_url="<gdk_url>/-/jwks" \
    bound_issuer="<gdk_url>"
```

### Testing that Vault is working

Generate a JWT configured for the project that you used when creating a Vault authentication role:

```shell
read CI_JOB_JWT < <(bundle exec rails runner 'puts Gitlab::Ci::Jwt.new(Project.find(<project_id>).builds.last, ttl: 300).encoded')
```

Authenticate with Vault using the JWT:

```shell
vault write auth/gitlab/login role=gitlab-test-role jwt=$CI_JOB_JWT
```

Using the token returned above (it looks like `s.bzDn9fAAAtrs9tV7fKGJ4Ksc`) read the `gitlab-test/db` secrets:

```shell
VAULT_TOKEN='<vault_token>' vault kv get kv-v2/gitlab-test/db
```
