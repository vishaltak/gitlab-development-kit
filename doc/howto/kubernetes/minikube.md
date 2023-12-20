# Install GDK on minikube

GDK can be deployed to minikube / Kubernetes.

Note that this setup is an experimental phase and [not officially supported](../../../README.md#installation).

You can't develop GitLab using this strategy yet.

See [issue about](https://gitlab.com/gitlab-org/gitlab-development-kit/issues/243) for more details.

## How to use it?

1. [Install minikube](https://minikube.sigs.k8s.io/docs/start/)
1. Clone GDK repository
1. Start minikube using `minikube start`
1. Create pod using `kubectl create -f gdkube.yml`
1. See starting pod using `kubectl get pods`
1. Wait until GDK starts, see a progress in logs `kubectl logs -f gdk-[pod-id]`
1. Get the URL to GDK by typing `minikube service gdk --url`
1. Open GDK in the browser
