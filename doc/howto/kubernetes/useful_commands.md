# Kubernetes - useful commands

This is a reference list of some useful commands one might need when contributing to Auto DevOps.

Be sure also to check our [Tips and Troubleshooting](tips_and_troubleshooting.md) section.

## `kubectl` Config

View your full `kubectl` config:

```shell
kubectl config view
```

or:

```shell
cat ~/.kube/config
```

You can also view a specific config, like getting the list of known clusters:

```shell
kubectl config get-cluster
```

or, _very important_, know to which context your kubectl is current connected to:

```shell
kubectl config current-context
```

This determines if you're communicating to your local development cluster (minikube for instance) or your remote cluster (hosted on GKE for instance). It also determines which cluster [Helm](#helmtiller-commands) communicates to.

## Change your current context

If you'd like to change your current-context to point to a different cluster, with `gcloud`, you can:

```shell
gcloud container clusters get-credentials cluster-name-here
```

## Get Nodes, Pods, Deployments, Jobs, Secrets

You can get one information at a time:

```shell
kubectl get nodes
```

or many at once:

```shell
kubectl get nodes,pods,deployments,jobs,secrets
```

`kubectl` looks for objects in the `default` namespace. So to see our GitLab deployed objects, use this flag:

```shell
kubectl get pods -n gitlab-managed-apps
```

or:

```shell
kubectl get pods --all-namespaces
```

## Logging Pods

To see the complete log:

```shell
kubectl logs pod-name-here -n gitlab-managed-apps
```

or to see the last *n* lines use the `--tail` flag:

```shell
kubectl logs {pod-name-without-braces} --tail=20 -n gitlab-managed-apps
```

you can combine it with `watch` to keep reading the file every *n* seconds:

```shell
watch -n3 kubectl logs {pod-name-without-braces} --tail=20 -n gitlab-managed-apps
```

if you're on mac you might need to install `watch` first:

```shell
brew install watch
```

## Helm/Tiller Commands

[Helm 2](https://v2.helm.sh/docs) is the package manager for Kubernetes. When
running `helm` commands on your local machine, Helm
communicates with a [Tiller](https://v2.helm.sh/docs/glossary/#tiller) server
(usually an in-cluster component). Tiller interacts directly with the
Kubernetes API server to install, upgrade, query, and remove Kubernetes
resources. It also stores the objects that represent releases.

To initialize [Helm](https://docs.helm.sh/) on your machine run:

```shell
helm init --client-only
```

(without the `--client-only` flag, `helm init` attempts to install a Tiller server).

### Interacting with Helm releases

Before you start:

1. Make sure your `kubectl config current-context` [points to the correct cluster](#change-your-current-context).
1. Find the namespace that contains your Helm release data:
    - All [GitLab-managed apps](https://docs.gitlab.com/ee/user/clusters/applications.html) are
      installed using Helm under the `gitlab-managed-apps` namespace.
    - [Auto DevOps](https://docs.gitlab.com/ee/topics/autodevops/index.html) also
      uses Helm for its deployments. Generally, each environment gets its own
      namespace, and each namespace has its own release data.

#### Local Tiller

You can always interact with the in-cluster metadata using a local Tiller (even
if a remote Tiller is present).

In this example, we assume the environment variable `KUBE_NAMESPACE` is the
namespace containing your releases (for example, `gitlab-managed-apps`). To
start a local Tiller and prepare Helm,
run:

```shell
export TILLER_NAMESPACE=$KUBE_NAMESPACE
export HELM_HOST="localhost:44134"
tiller -listen "$HELM_HOST" &
helm init --client-only
```

To confirm the commands worked properly, run:

```shell
helm version # should output client and server versions
helm list    # should output the releases stored in the given namespace
```

#### Remote Tiller (for GitLab-managed apps)

Prior to GitLab 13.2, GitLab used a remote Tiller server in the
`gitlab-managed-apps` namespace for the GitLab-managed apps.
(Not Auto DevOps, which has used a local Tiller for a long time.) This Tiller
is configured with SSL communication enabled, so we need to retrieve
certificates from the backend to talk to it.

Run the following in a rails console (`bundle exec rails c`):

```ruby
helm = Clusters::Applications::Helm.last; nil

File.open('/tmp/ca_cert.pem', 'w') { |f| f.write(helm.ca_cert) }; nil

client_cert = helm.issue_client_cert; nil

File.open('/tmp/key.pem', 'w') { |f| f.write(client_cert.key_string) }; nil
File.open('/tmp/cert.pem', 'w') { |f| f.write(client_cert.cert_string) }; nil
```

Now we already have proper SSL files, `/tmp/ca_cert.pem`, `/tmp/key.pem` and `/tmp/cert.pem`, and can use them to talk to Tiller:

```shell
helm version --tls \
  --tls-ca-cert /tmp/ca_cert.pem \
  --tls-cert /tmp/cert.pem \
  --tls-key /tmp/key.pem \
  --tiller-namespace=gitlab-managed-apps
```

Note that we stopped using `--client-only`, but instead we added the TLS flags
and the `--tiller-namespace=gitlab-managed-apps` flag. To make this process
less verbose, we can use a simple bash function to fetch and use our certs:

```shell
function gitlab-helm() {
  [ ! -d ~/.gitlab-helm ] && mkdir ~/.gitlab-helm
  [ -f ~/.gitlab-helm/tiller-ca.crt ] || (kubectl get secrets/tiller-secret -n gitlab-managed-apps -o "jsonpath={.data['ca\.crt']}"  | base64 --decode > ~/.gitlab-helm/tiller-ca.crt)
  [ -f ~/.gitlab-helm/tiller.crt ]    || (kubectl get secrets/tiller-secret -n gitlab-managed-apps -o "jsonpath={.data['tls\.crt']}" | base64 --decode > ~/.gitlab-helm/tiller.crt)
  [ -f ~/.gitlab-helm/tiller.key ]    || (kubectl get secrets/tiller-secret -n gitlab-managed-apps -o "jsonpath={.data['tls\.key']}" | base64 --decode > ~/.gitlab-helm/tiller.key)
  helm "$@" --tiller-connection-timeout 1 --tls \
    --tls-ca-cert ~/.gitlab-helm/tiller-ca.crt \
    --tls-cert ~/.gitlab-helm/tiller.crt \
    --tls-key ~/.gitlab-helm/tiller.key \
    --tiller-namespace gitlab-managed-apps
}
```

WARNING:
The credentials should be cleared when switching `kubectl`
contexts, to avoid performing Helm operations on the wrong cluster:

```shell
function gitlab-helm-purge-credentials() {
  rm -rf ~/.gitlab-helm
}
```
