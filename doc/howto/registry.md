# Container Registry

Depending on your needs, you can set up Container Registry locally in the following ways:

- Display the Container Registry in the UI only (not push or pull images).
- Use the Container Registry as an insecure registry (can push and pull images).
- Use the Container Registry with a self-signed certificate (can push and pull images).

## Check AirPlay Receiver process on macOS

If you are running macOS Monterey, the `AirPlay Receiver` process
[may be listening on port 5000](https://developer.apple.com/forums/thread/682332). This
interferes with the Container Registry if it's bound to localhost, as it
listens on the same port. See the [Apple support thread](https://developer.apple.com/forums/thread/682332) for instructions on
turning off AirPlay Receiver temporarily.

To check if AirPlay Receiver is listening on port 5000, you can run
`curl` with the `-i` flag to include protocol response headers:

```shell
curl -i registry.test:5000
```

If you see `Server: AirTunes/605.1` in the response, AirPlay Receiver is
listening on the port and should be disabled.

## Set up Container Registry to display in UI only

To set up Container Registry to display in the UI only (but not be able to push or pull images) add the following to your `gdk.yml`:

```yaml
registry:
  enabled: true
```

Then run the following commands:

1. `gdk reconfigure`.
1. `gdk restart`.

## Set up pushing and pulling of images over HTTP

To set up Container Registry to allow pushing and pulling of images over HTTP, you must have a Docker-compatible client
installed. For example:

- [Docker CLI](https://docs.docker.com/engine/reference/commandline/cli/).
- [Colima](https://github.com/abiosoft/colima).
- [`lima nerdctl`](https://github.com/containerd/nerdctl).
- [Rancher Desktop](https://rancherdesktop.io).
- [Podman](https://podman.io/)

In these instructions, we assume you [set up `registry.test`](local_network.md).

1. Update `gdk.yml` as follows:

   ```yaml
   hostname: gdk.test
   registry:
     enabled: true
     host: registry.test
     self_signed: false
     auth_enabled: true
     listen_address: 0.0.0.0
   ```

1. Locate the Docker daemon configuration file and set the `insecure-registries` directive to point to the local registry `registry.test:5000`:
   - For Rancher Desktop, see [modify Docker daemon configuration in Rancher Desktop VM](https://github.com/rancher-sandbox/rancher-desktop/discussions/1477).
   - For Colima, see [How to customize Docker config e.g. add insecure registries?](https://github.com/abiosoft/colima/blob/main/docs/FAQ.md#how-to-customize-docker-config-eg-add-insecure-registries).
   - For general information, see the [Docker documentation](https://docs.docker.com/registry/insecure/#deploy-a-plain-http-registry).
1. Restart the Docker engine.
1. Run `gdk reconfigure`.
1. Run `gdk restart`.

After completing these instructions, you should be ready to work with the registry locally. See the
[Interacting with the local container registry](#interacting-with-the-local-container-registry)
section for examples of how to query the registry manually using `curl`.

### Set up pushing and pulling of images over HTTPS

This section is relevant if you set `self_signed: true` in your `gdk.yml`.

Since the registry is self-signed, Docker treats it as *insecure*. The certificate must be in your
GDK root, called `registry_host.crt`, and must be copied as `ca.crt` to the
[appropriate Docker configuration location](https://docs.docker.com/registry/insecure/#use-self-signed-certificates).

If you are using Docker Desktop for Mac, GDK includes the shorthand:

```shell
rm -f registry_host.{key,crt} && make trust-docker-registry
```

This places the certificate under `~/.docker/certs.d/$REGISTRY_HOST:$REGISRY_PORT/ca.crt`, *overwriting any existing certificate* at that path.

Afterwards, you **must restart Docker** to apply the changes.

### Observe the registry

Run `gdk tail registry`.

Example:

```plaintext
registry   : level=warning msg="No HTTP secret provided - generated random secret ...
registry   : level=info msg="redis not configured" go.version=go1.11.2 ...
registry   : level=info msg="Starting upload purge in 13m0s" go.version=go1.11.2 ...
registry   : level=info msg="using inmemory blob descriptor cache" go.version=go1.11.2 ...
registry   : level=info msg="listening on [::]:5000" go.version=go1.11.2 ...
```

Use `docker ps` to see if there is a registry container running:

```shell
$ docker ps


CONTAINER ID        IMAGE                                                                                    COMMAND                  CREATED             STATUS              PORTS                    NAMES
61b7b150be33        registry.gitlab.com/gitlab-org/build/cng/gitlab-container-registry:v2.9.1-gitlab         "/entrypoint.sh /etc…"   2 minutes ago       Up 2 minutes        0.0.0.0:5000->5000/tcp   priceless_hoover
```

Visit `$REGISTRY_HOST:$REGISTRY_PORT` (such as `registry.test:5000`) in your browser.
Any response, even a blank page, means that the registry is probably running. If the
registry is running, the output of `gdk tail` changes.

### Configure an insecure registry for GitLab CI/CD

If your're not using a self-signed certificate, you can instruct Docker to consider the registry as insecure. For example, Docker-in-Docker builds require an additional flag, `--insecure-registry`:

```yaml
# .gitlab-ci.yml

services:
  - name: docker:stable-dind
    command: ["--insecure-registry=registry.test:5000"]
```

### Configure a local Docker-based runner

For Docker-in-Docker builds to work in a local runner, you must also make the nested Docker
service trust the certificates by editing `volumes` under `[[runners.docker]]` in your
runner's `.toml` configuration to include:

```shell
$HOME/.docker/certs.d:/etc/docker/certs.d
```

replacing `$HOME` with the expanded path. For example

```toml
volumes = ["/Users/hfyngvason/.docker/certs.d:/etc/docker/certs.d", "/certs/client", "/cache"]
```

### Interacting with the local container registry

In this section, we assume you have obtained a [Personal Access Token](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html) with all permissions, and exported it as `GITLAB_TOKEN` in your environment:

```shell
export GITLAB_TOKEN=...
```

#### Using the Docker Client

- If you have authentication enabled, logging in is required.
- If you have a self-signed local registry, trusting the registry's certificates is required.

##### Log in to the registry

```shell
docker login gdk.test:5000 -u gitlab-token -p "$GITLAB_TOKEN"
```

##### Build and tag an image

```shell
docker build -t gdk.test:5000/custom-docker-image .
```

##### Push the image to the local registry

```shell
docker push gdk.test:5000/custom-docker-image
```

#### Using HTTP

- If you have a self-signed certificate, you can add `--cacert registry_host.crt` or `-k` to the `curl` commands.
- If you have authentication enabled, you must obtain a bearer token for your requests:

  ```shell
  export GITLAB_REGISTRY_JWT=`curl "http://gitlab-token:$GITLAB_TOKEN@gdk.test:3000/jwt/auth?service=container_registry&scope=$SCOPE" | jq -r .token`
  ```

  where `$SCOPE` should be
  - `registry:catalog:*` to interact with the catalog
  - `repository:your/project/path:*` to interact with the images associated with a particular project

  Alternatively, you can obtain the token via the Rails console:

  ```ruby
  ::Auth::ContainerRegistryAuthenticationService.pull_access_token('your/project/path')
  ```

  To use the token, append it as a header flag to the `curl` command:

  ```shell
  -H "Authorization: Bearer $GITLAB_REGISTRY_JWT"
  ```

The commands below assume a self-signed registry with authentication enabled, as this is the most complicated use case.

##### Retrieve a list of images available in the repository

```shell
curl --cacert registry_host.crt -H "Authorization: Bearer $GITLAB_REGISTRY_JWT" \
  gdk.test:5000/v2/_catalog
```

```json
{
  "repositories": [
    "secure-group/docker-image-test",
    "secure-group/klar",
    "secure-group/tests/ruby-bundler/master",
    "testing",
    "ubuntu"
  ]
}
```

##### List tags for a specific image

```shell
curl --cacert registry_host.crt -H "Authorization: Bearer $GITLAB_REGISTRY_JWT" \
  gdk.test:5000/v2/secure-group/tests/ruby-bundler/master/tags/list
```

```json
{
  "tags": [
    "3bf5c8efcd276bf6133ccb787e54b7020a00b99c",
    "ca928571c661c42dbdadc090f4ef78c8f2854dd9",
    "f7182b792a58d282ef3c69c2c6b7a22f78b2e950"
  ], "name": "secure-group/tests/ruby-bundler/master"
}
```

##### Get image manifest

```shell
curl --cacert registry_host.crt -H "Authorization: Bearer $GITLAB_REGISTRY_JWT" \
  gdk.test:5000/v2/secure-group/tests/ruby-bundler/master/manifests/3bf5c8efcd276bf6133ccb787e54b7020a00b99c
```

```json
{
  "schemaVersion": 1,
  "name": "secure-group/tests/ruby-bundler/master",
  "tag": "3bf5c8efcd276bf6133ccb787e54b7020a00b99c",
  "architecture": "amd64",
  "fsLayers": [
      {
        "blobSum": "sha256:f9b473be28291374820c40f9359f7f1aa014babf44aadb6b3565c84ef70c6bca"
      },
  "..."
```

##### Get image layers

```shell
curl --cacert registry_host.crt \
  -H "Authorization: Bearer $GITLAB_REGISTRY_JWT" \
  -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' \
  gdk.test:5000/v2/secure-group/tests/ruby-bundler/master/manifests/3bf5c8efcd276bf6133ccb787e54b7020a00b99c
```

```json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
  "config": {
    "mediaType": "application/vnd.docker.container.image.v1+json",
    "size": 7682,
    "digest": "sha256:b5c7d3594559132203ca916d26e969f7bf6492d2e80d753db046dff06a5303e6"
  },
  "layers": [
    {
        "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
        "size": 45342599,
        "digest": "sha256:e79bb959ec00faf01da52437df4fad4537ec669f60455a38ad583ec2b8f00498"
    },
    "..."
```

##### Get content of image layer

```shell
curl --cacert registry_host.crt -H "Authorization: Bearer $GITLAB_REGISTRY_JWT" \
  gdk.test:5000/v2/secure-group/tests/ruby-bundler/master/blobs/sha256:e79bb959ec00faf01da52437df4fad4537ec669f60455a38ad583ec2b8f00498
```

### Using a custom Docker image as the main pipeline build image

It's possible to use the local GitLab container registry as the source of the build image in
pipelines.

1. Create a new project called `custom-docker-image` with the following `Dockerfile`:

   ```dockerfile
   FROM alpine
   RUN apk add --no-cache --update curl
   ```

1. Build and tag an image from within the same directory as the `Dockerfile` for the project.

   ```shell
   docker build -t gdk.test:5000/custom-docker-image .
   ```

1. Push the image to the registry. (See [Configuring the GitLab Docker runner to automatically pull images](#configuring-the-gitlab-docker-runner-to-automatically-pull-images) for the preferred method which doesn't require you to constantly push the image after each change.)

   ```shell
   docker push gdk.test:5000/custom-docker-image
   ```

   You should follow the directions given in the [Configuring the GitLab Docker runner to automatically pull images](#configuring-the-gitlab-docker-runner-to-automatically-pull-images) section to avoid pushing images altogether.

1. Create a `.gitlab-ci.yml` and add it to the Git repository for the project. Configure the `image` directive in the `.gitlab-ci.yml` file to reference the `custom-docker-image` which was tagged and pushed in previous steps:

   ```yaml
   image: gdk.test:5000/custom-docker-image

   stages:
     - test

   custom_docker_image_job:
     allow_failure: false
     script:
       - curl -I httpstat.us/201
   ```

1. The CI job should now pass and execute the `curl` command which we previously added to our base image:

   ```shell
   # CI job log output
   curl -I httpstat.us/201

   HTTP/1.1 201 Created
   ```

### Configuring the GitLab Docker runner to automatically pull images

In order to avoid having to push the Docker image after every change, it's
possible to configure the GitLab Runner to automatically pull the image
if it isn't present. This can be done by setting `pull_policy = "if-not-present"`
in the Runner's config.

```toml
# ~/.gitlab-runner/config.toml

[[runners]]
  name = "docker-executor"
  url = "http://gdk.test:3000/"
  token = "<my-token>"
  executor = "docker"
  [runners.custom_build_dir]
  [runners.docker]
    image = "ruby:2.6.3"
    privileged = true
    # When the if-not-present pull policy is used, the Runner will first check if the image is present locally.
    # If it is, then the local version of image will be used. Otherwise, the Runner will try to pull the image.
    pull_policy = "if-not-present"
```

### Building and pushing images to your local GitLab container registry in a build step

It's sometimes necessary to use the local GitLab container registry in a pipeline. For
example, the [container scanning](https://docs.gitlab.com/ee/user/application_security/container_scanning/#example)
feature requires a build step that builds and pushes a Docker image to the registry before it can analyze the image.

To add a custom `build` step as part of a pipeline for use in later jobs
such as container scanning, add the following to your `.gitlab-yml.ci`:

```yaml
image: docker:stable

services:
  - name: docker:stable-dind
    command: ["--insecure-registry=gdk.test:5000"] # Only required if the registry is insecure

stages:
  - build

build:
  stage: build
  variables:
    DOCKER_TLS_CERTDIR: ""
  script:
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" "$CI_REGISTRY"
    - docker pull $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA || true
    - docker build -t $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA
```

To verify that the build stage has successfully pushed an image to your local GitLab container registry, follow the instructions in the section [List tags for a specific image](#list-tags-for-a-specific-image).

**Some notes about the above `.gitlab-yml.ci` configuration file:**

- The variable `DOCKER_TLS_CERTDIR: ""` is required in the `build` stage because of a breaking change introduced by Docker 19.03, described [here](https://about.gitlab.com/2019/07/31/docker-in-docker-with-docker-19-dot-03/).
- It's only necessary to set `--insecure-registry=gdk.test:5000` for the `docker:stable-dind` if you have not set up a [trusted self-signed registry](#set-up-pushing-and-pulling-of-images-over-https).

### Running container scanning on a local Docker image created by a build step in your pipeline

It's possible to use a `build` step to create a custom Docker image and then execute a
[container scan](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning) against this newly
built Docker image. This can be achieved by using the following `.gitlab-ci.yml`:

```yaml
include:
  template: Container-Scanning.gitlab-ci.yml

image: docker:stable

services:
  - name: docker:stable-dind
    command: ["--insecure-registry=gdk.test:5000"] # Only required if the registry is insecure

stages:
  - build
  - test

build:
  stage: build
  variables:
    DOCKER_TLS_CERTDIR: ""
  script:
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" "$CI_REGISTRY"
    - docker pull $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA || true
    - docker build -t $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA

container_scanning:
  variables:
    CS_REGISTRY_INSECURE: "true" # see note below for discussion
```

NOTE:
The contents of the above `.gitlab-ci.yml` file differs depending on how the container registry has been configured:

1. When the local container registry is insecure because `registry.self_signed: false` has been
   configured, the above `.gitlab-ci.yml` file can be used.

   It's necessary to set `CS_REGISTRY_INSECURE: "true"` in the `container_scanning` job for the
   GitLab Container Scanning tool ([`gcs`](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/))
   to fetch the image from our registry using `HTTPS`, meanwhile our registry is running insecurely over `HTTP`.
   Setting the `CS_REGISTRY_INSECURE` as documented [here](https://docs.gitlab.com/ee/user/application_security/container_scanning/#available-cicd-variables),
   forces `gcs` to use `HTTP` when fetching the container image from our insecure registry.

1. When the registry is secure because `registry.self_signed: true` has been configured, but we
   haven't referenced the self-signed certificate, then the following `services` and
   `container_scanning` sections of the above `.gitlab-ci.yml` must be used (the rest of the file
   has been omitted for brevity):

   ```yaml
   services:
     - docker:stable-dind

   container_scanning:
     variables:
       CS_DOCKER_INSECURE: "true"
   ```

   Since the local container registry is now running securely over an `HTTPS` connection, we no longer need to use `CS_REGISTRY_INSECURE: "true"`. However, we need to set the `CS_DOCKER_INSECURE: "true"` option to instruct `gcs` to accept a self-signed certificate.

1. When the registry is secure because `registry.self_signed: true` has been configured, **and** we
  reference the self-signed certificate, then the following `services` and `container_scanning`
  sections of the above `.gitlab-ci.yml` must be used (the rest of the file has been omitted for
  brevity):

   ```yaml
   services:
     - docker:stable-dind

   container_scanning:
     variables:
       ADDITIONAL_CA_CERT_BUNDLE: "-----BEGIN CERTIFICATE----- certificate-goes-here -----END CERTIFICATE-----"
   ```

   By configuring the `ADDITIONAL_CA_CERT_BUNDLE`, this instructs `gcs` to use the provided certificate when accessing the local container registry. Normally, the `ADDITIONAL_CA_CERT_BUNDLE` would be [configured in the UI](https://docs.gitlab.com/ee/ci/variables/#create-a-custom-variable-in-the-ui), but it's displayed here in the `.gitlab-ci.yml` for demonstration purposes.

### Switching Between `docker-desktop-on-mac` and `docker-machine`

To determine if you're using `docker-machine`, execute the following command:

```shell
export | grep -i docker

DOCKER_CERT_PATH=~/.docker/machine/machines/default
DOCKER_HOST=tcp://192.168.99.100:2376
DOCKER_MACHINE_NAME=default
DOCKER_TLS_VERIFY=1
```

If a list of environment variables are returned as above, this means that you're currently using `docker-machine` and any `docker` commands are routed to the virtual machine controlled by `docker-machine`.

To switch from `docker-machine` to `docker-desktop-for-mac`, simply unset the above environment variables:

```shell
unset DOCKER_CERT_PATH DOCKER_HOST DOCKER_MACHINE_NAME DOCKER_TLS_VERIFY
```

### Using a Development Image of the Container Registry

To test development versions of the container registry against GDK:

1. Within the [container registry](https://gitlab.com/gitlab-org/container-registry) project root, build and tag an image that includes your changes:

   ```shell
   docker build -t registry:dev .
   ```

1. Write the image tag in the `registry_image` file and reconfigure GDK:

   ```shell
   echo registry:dev > registry_image
   gdk reconfigure
   ```

1. Restart GDK:

   ```shell
   gdk restart
   ```

1. Inspect Docker to confirm that the development image of the registry is running locally:

   ```shell
   docker ps
   CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
   bc6c0efa5582        registry:dev        "registry serve /etc…"   7 seconds ago       Up 6 seconds                            romantic_nash
   ```

### Use local GitLab container registry with AutoDevops pipelines

When testing AutoDevops pipelines with a local registry, you can receive errors in the build step:

- If a registry with self-signed certificate is used:

  ```shell
  $ /build/build.sh
  Logging to GitLab Container Registry with CI credentials...
  Error response from daemon: Get https://gdk.test:5000/v2/: x509: certificate signed by unknown authority
  ERROR: Job failed: command terminated with exit code 1
  ```

- If a registry with insecure registry is used:

  ```shell
  $ /build/build.sh
  Logging to GitLab Container Registry with CI credentials...
  Error response from daemon: Get https://gdk.test:5000/v2/: http: server gave HTTP response to HTTPS client
  ERROR: Job failed: command terminated with exit code 1
  ```

To fix such issues, you can customize your `build` job as a part of an AutoDevOps pipeline,
by adding the following to your `.gitlab-ci.yml`:

```yaml
include:
  - template: Auto-DevOps.gitlab-ci.yml

build:
  services:
    - name: docker:stable-dind
      # Only required if the registry is insecure or used self signed certificate
      command: ["--insecure-registry=gdk.test:5000"]
```

And for example, if you have minikube as a Kubernetes runner
and you configured a self-signed registry, you can add a generated certificate to Docker inside of minikube:

1. Run the following on your GDK instance:

   ```shell
   $ cat ~/.docker/certs.d/gdk.test\:5000/ca.crt
   -----BEGIN CERTIFICATE-----
   ...
   -----END CERTIFICATE-----
   ```

1. Copy this certificate to minikube:

   ```shell
   $ minikube ssh
   $ sudo mkdir -p /etc/docker/certs.d/gdk.test\:5000
   $ sudo tee /etc/docker/certs.d/gdk.test\:5000/ca.crt > /dev/null <<EOT
   -----BEGIN CERTIFICATE-----
   ...
   -----END CERTIFICATE-----
   EOT
   $ sudo systemctl restart docker
   $ logout
   ```

Or if you are using insecure registry, you can run minikube with command like:

```shell
minikube start --insecure-registry="gdk.test:5000"
```

Then the AutoDevOps pipeline should be able to build images and run them inside of Kubernetes.

### Troubleshooting

#### Container Registry fails to start in Podman

If the [container registry is failing to start](#container-registry-fails-to-start) while using Podman,
check if the container logs contain `configuration error: open /etc/docker/registry/config.yml: permission denied`.
If so, you can specify the `uid` and `gid` for the [`docker run -u` option](https://docs.podman.io/en/latest/markdown/podman-run.1.html#user-u-user-group)
in your `gdk.yml`:

```yaml
registry:
  uid: '0'
  gid: '0'
```

WARNING:
Using a `uid` of `0` sets the containers to run as root, which is not considered best practice.

#### Container Registry fails to start

The Container Registry is failing to start if you run:

- `gdk tail registry`, and this shows output similar to the following:

  ```plaintext
  2022-10-28_21:41:21.24738 registry              : runit control/t: sending TERM to -18831
  2022-10-28_21:41:21.24741 registry              : runit control/t: sending TERM to 18831
  ```

- `docker ps` repeatedly, and this occasionally and briefly shows a container, similar to the following:

  ```plaintext
  f791ddfd5a10  registry.gitlab.com/gitlab-org/build/cng/gitlab-container-registry:v3.49.0- 
  gitlab  /scripts/process-...  Less than a second ago  Up Less than a second ago (starting)  
  0.0.0.0:5000->5000/tcp  awesome_benz
  ```

The container error is not visible anywhere, and the container is immediately removed. To see the error in the container's logs, you must prevent the container from being immediately removed:

1. Remove the `--rm` option from [the `docker run` command](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/991bfff80de158d78d48b479852398a60a4c22ee/support/docker-registry#L23).
1. To see exactly what is being run, copy the `docker run` command and `echo` it before the `exec` line.
1. Run `gdk start registry && gdk tail registry`.
1. Wait until the command is outputted.
1. To exit `gdk tail registry`, press <kbd>Control</kbd>+<kbd>C</kbd>.
1. To stop GDK from creating containers, run `gdk stop registry`.

Now you can find the container and view its logs:

1. Run `docker ps -a` to find the container name.
1. Run `docker logs <container_name>`.

The output should look similar to the following:

```plaintext
$ gdk start registry && gdk tail registry
ok: run: /Users/mkozonogitlab/Developer/gdk/services/registry: (pid 20314) 0s, normally down
2022-10-28_21:41:21.24738 registry              : runit control/t: sending TERM to -18831
2022-10-28_21:41:21.24741 registry              : runit control/t: sending TERM to 18831
2022-10-28_21:46:38.72345 registry              : docker run -p 172.16.123.1:5000:5000 -u 0:0 -v /Users/mkozonogitlab/Developer/gdk/registry/config.yml:/etc/docker/registry/config.yml:ro -v /Users/mkozonogitlab/Developer/gdk/registry/storage:/var/lib/registry -v /Users/mkozonogitlab/Developer/gdk/localhost.crt:/etc/docker/registry/localhost.crt:ro -v /Users/mkozonogitlab/Developer/gdk/registry_host.crt:/etc/docker/registry/registry_host.crt:ro -v /Users/mkozonogitlab/Developer/gdk/registry_host.key:/etc/docker/registry/registry_host.key:ro registry.gitlab.com/gitlab-org/build/cng/gitlab-container-registry:v3.88.0-gitlab
^C
$ gdk stop registry
ok: down: /Users/mkozonogitlab/Developer/gdk/services/registry: 0s
$ docker ps -a
CONTAINER ID  IMAGE                                                                              COMMAND               CREATED         STATUS                                PORTS                                           NAMES
e73941e70bec  registry.gitlab.com/gitlab-org/build/cng/gitlab-container-registry:v3.88.0-gitlab  /scripts/process-...  24 seconds ago  Exited (1) 24 seconds ago (starting)  172.16.123.1:5000->5000/tcp                     focused_aryabhata
$ docker logs focused_aryabhata
configuration error: open /etc/docker/registry/config.yml: permission denied
Usage:
  registry serve <config> [flags]

Flags:
  -h, --help   help for serve
```

#### Missing container repositories in the UI

The container registry UI may only show one repository even after pushing two or more repositories.
This may happen if authentication between the registry and GitLab is disabled (`auth_enabled: false`).
To enable authentication follow these steps:

1. Under the `registry` section in your `gdk.yml` file, make sure that `auth_enabled` is set to `true`:

   ```yaml
   registry:
     auth_enabled: true
   ```

1. Run `gdk reconfigure`.
1. Run `gdk restart`.
1. Navigate to your project's **Container Registry** page and verify more images show up in the UI.
