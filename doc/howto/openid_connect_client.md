# Open ID Connect Client

GitLab provides an option to log in to GitLab from an Identity provider using OIDC . Keycloak is an open-source Identity provider which supports SAML and OIDC specification. 

These settings are for development environment, and not safe to use in production, refer [Documentation](https://docs.gitlab.com/ee/administration/auth/oidc.html) for production configuration

## Installation

1. Install Java Runtime Environment

```shell
 brew install java
 sudo ln -sfn /opt/homebrew/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk
```

1. Download from Keycloak [downloads](https://www.keycloak.org/downloads).
1. Unpack the ZIP file using the appropriate unzip utility, such as jar, tar, or unzip.
1. Run the application in development mode

```shell
./bin/kc.sh start-dev
```

You can optionally use PostgreSQL database as the default database adapter crashes often 

```shell
createdb postgres
./bin/kc.sh start-dev --db postgres
```

1. Open localhost:8080 from your browser, and you will be greeted with the initial setup page. you can specify default credentials here.

### Installation with Docker

1. Start the Docker container using keycloak image

```shell
docker run --name keycloak -p 8180:8180 \
        -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin \
        quay.io/keycloak/keycloak:latest \
        start-dev \
        --http-port 8180 \
        --http-relative-path /auth

```

1. Open localhost:8180 from your browser, and you will be greeted with the initial setup page. you can specify default credentials here.

## Usage

Once the installation is done, you login with the credntial you set during installation step.

1. Visit `http://localhost:8080/` and create default administrator
1. Visit `http://localhost:8080/admin` enter credentials created from previous step
1. Keycloak's top-level abstraction is the realm which are the isolated environment for users. You can use default namespace to simplify the process.
1. Once is the realm is setup, click on the `Clients` button on the sidebar.
1. Click on the `Create Client` button
1. Fill the form with following details and click`next`
    - client type as `OpenID connect`
    - client ID as `gdk` 
1. Toggle `Client authentication` and press `next`
1. Fill the access settings page with following details
    - Root URL -> `https://gdk.test:3000`
    - Home URL -> `https://gdk.test:3000`
    - Valid Redirect URLS -> `/users/auth/openid_connect/callback`
1. Head over to `Client Scopes` tab and click on `gdk-dedicated`
1. Click on `Add predefined mapper` , select `username` and click `Add` button
1. Copy `Client secret` from `Credentials` tab
1. Open `gdk.yml` and add following details

```yaml
omniauth:
  openid_connect:
    enabled: true
    issuer: 'http://localhost:8080/realms/master'
    args:
      response_type: 'code'
      uid_field: 'preferred_username'
      issuer: 'http://localhost:8080/realms/master'
      client_options:
        port: 8080
        scheme: 'http'
        identifier: 'gdk'
        host: 'localhost'
        secret: 'secret' #secret copied from Step 10
        authorization_endpoint: 'http://localhost:8080/realms/master/protocol/openid-connect/auth'
        token_endpoint: 'http://localhost:8080/realms/master/protocol/openid-connect/token'
        userinfo_endpoint: 'http://localhost:8080/realms/master/protocol/openid-connect/userinfo'
        jwks_uri: 'http://localhost:8080/realms/master/protocol/openid-connect/certs'
        redirect_uri: 'https://gdk.test:3000/users/auth/openid_connect/callback'
```

1. Run `gdk reconfigure`
1. Visit `gdk.test:3000` unauthenticated and click on `openid connect` to log in
