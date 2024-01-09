# frozen_string_literal: true

module GDK
  # This class configures a Vault dev server to allow the project with the given ID to fetch secrets using the
  # `gitlab.ci.yml` `secrets` keyword
  class Vault
    def create_test_secret
      enable_secrets_engine_cmd = 'vault secrets enable -path=kv-v2 kv-v2'
      add_secret_cmd = 'vault kv put kv-v2/gitlab-test/db password=db-password-goes-here'

      shellout(enable_secrets_engine_cmd)
      shellout(add_secret_cmd)
    end

    def create_test_policy
      vault_policy_cmd = <<~VAULT_POLICY
        vault policy write gitlab-test-policy - <<EOF
        path "kv-v2/data/gitlab-test/*" {
          capabilities = [ "read" ]
        }
        EOF
      VAULT_POLICY

      shellout(vault_policy_cmd)
    end

    def configure_test_auth(project_id)
      enable_jwt_auth_cmd = 'vault auth enable -path=gitlab jwt'

      vault_write_auth_cmd = <<~VAULT_AUTH
        vault write auth/gitlab/config \
          jwks_url="#{GDK.config.__uri}/-/jwks" \
          bound_issuer="#{GDK.config.__uri}"
      VAULT_AUTH

      shellout(enable_jwt_auth_cmd)
      shellout(vault_write_auth_cmd)
      shellout(vault_role_cmd(project_id))
    end

    def print_example_ci_config
      GDK::Output.notice(
        <<~VAULT_CI_EXAMPLE
          \n\nYou can now fetch a secret from Vault with the following CI job:

          test_secrets:
            variables:
              VAULT_AUTH_PATH: gitlab
              VAULT_AUTH_ROLE: gitlab-test-role
              VAULT_SERVER_URL: #{vault_address}
            id_tokens:
              TEST_ID_TOKEN:
                aud: #{GDK.config.__uri}
            secrets:
              DATABASE_PASSWORD:
                vault: gitlab-test/db/password
            script:
              - echo $DATABASE_PASSWORD
              - cat $DATABASE_PASSWORD
        VAULT_CI_EXAMPLE
      )
    end

    private

    def shellout(*)
      Shellout.new({ 'VAULT_ADDR' => vault_address }, *).execute
    end

    def vault_address
      "http://#{GDK.config.vault.listen_address}:8200"
    end

    def vault_role_cmd(project_id)
      <<~VAULT_ROLE
        vault write auth/gitlab/role/gitlab-test-role - <<EOF
        {
          "role_type": "jwt",
          "policies": ["gitlab-test-policy"],
          "token_explicit_max_ttl": 600,
          "user_claim": "user_email",
          "bound_claims": {
            "project_id": "#{project_id}"
          },
          "bound_audiences": "#{GDK.config.__uri}"
        }
        EOF
      VAULT_ROLE
    end
  end
end
