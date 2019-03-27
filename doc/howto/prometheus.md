# Using Prometheus with GDK

Testing the Prometheus integration with the GitLab Development Kit requires some additional components. This is because the Prometheus integration requires a CI/CD deploy on Kubernetes.

Because of this, you will need to either run a local Kubernetes cluster or use a service like the Google Container Engine (GKE).

Setting it up locally with [Minikube](https://github.com/kubernetes/minikube) is often easier, as you do not have to worry about Runners in GKE requiring network access to your local GDK instance.

## Setup Minikube

First, follow the instructions for [installing minikube](doc/howto/prometheus/minikube_installation.md), then familiarize yourself with the [recommended minikube usage](doc/howto/prometheus/minikube_usage.md). This includes a few shell scripts to add to your bash profile as well, which should make daily usage even simpler. If you choose not to use these scripts, the manual instructions are also provided.

## Create a Project

With GDK running, we need to go and create a project with CI/CD
set up. The easiest way to do this, is to import from an existing project with a simplified `gitlab-ci.yml`.

Import `https://gitlab.com/joshlambert/autodevops-deploy.git` as a public project, to use a very simple CI/CD pipeline with no requirements, based on AutoDevOps. It contains just the `deploy` stages and uses a static image, since the GDK does not contain a registry.

## Allow requests to the local network

We have CSRF protection in place on the cluster url, so if we try to connect minikube now, we'll get a `Requests to the local network are not allowed` error. The below steps will disable this protection for use with minikube.

1. As root user, navigate to **Admin Area** (the little wrench in the top nav) > **Settings** > **Network**.
1. Expand the **Outbound requests** section, check the box to *Allow requests to the local network from hooks and services*, and save your changes.

## Connect your cluster

1. Go to your Kubernetes cluster dashboard. If it is not open, you can open one by running `minikube dashboard --profile <machine-name>`.

1. At bottom of the page you will find a list of secrets, with one named `default`. Click on it to view it, you will need these values later.

1. In your GitLab instance, go to **Operations** ➔ **Kubernetes** in your project, then add a cluster. Select the option to add an existing cluster.

1. Enter any value for the `Kubernetes cluster name`.

1. For `API_URL`, use the "Cluster address" from the output of `mini-new` or `mini-start`.

  If this is unavailable, run `minikube ip --profile <machine-name>` in a terminal to get the API endpoint of your cluster. For `API URL`, enter `https://<MINIKUBE_IP>:8443` using this ip address.

1. For `CA Certificate`, paste in the value from your Kubernetes secret. Include the `----BEGIN CERTIFICATE----` and `----END CERTIFICATE----`, as they are part of a valid certificate.

1. Similarly for `Token`, paste the value from the Kubernetes secret.

1. Save your changes.

## Deploy Helm Tiller, Prometheus, and GitLab Runner

On the Kubernetes cluster screen in your GitLab instance, you should now be able to deploy Helm Tiller. Once complete, also deploy a Runner and Prometheus.

If you get an error about an API token not yet being created, wait a minute or two and try again.

If installing Helm Tiller fails with 'Kubernetes error', you may have an existing config. To remove it:

```shell
kubectl delete configmap values-content-configuration-helm -n gitlab-managed-apps
```

## Run a Pipeline to deploy to an Environment

Now that we have a Runner configured, we need to kick off a Pipeline. This is because the Prometheus integration only looks for environments which GitLab knows about and have a successful deploy. To do this, go into Pipelines and run a new Pipeline off `master`.

You can validate the deploy worked by looking at the Kubernetes dashboard, or accessing the URL.

To retrieve the URL:

```shell
minikube service production
```

Likewise, creating new Merge Requests will also create new pipelines and corresponding deployed review app environments.

## View Performance metrics

Go to **Operations ➔ Environments** then click on an Environment. You should see a new button appearing that looks like a chart. Click on it to view the metrics.

It may take 30-60 seconds for the Prometheus server to get a few sets of data points.
