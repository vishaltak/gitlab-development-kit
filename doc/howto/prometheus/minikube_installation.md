# Instructions for Minikube Installation

The following steps will help you set up Minikube locally.

## Install kubectl if you do not have it

Kubectl is required for Minikube to function. You can also use `homebrew` to install it using `brew install kubernetes-cli`.

1. First, download it:

   ```shell
   ## For macOS
   curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl

   ## For Linux
   curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
   ```

1. Then, add it to your path:

   ```shell
   chmod +x ./kubectl
   sudo mv ./kubectl /usr/local/bin/
   ```

## Install Minikube

For macOS with homebrew, run `brew cask install minikube`.

1. First, download it:

   ```shell
   ## For macOS
   curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64

   ## For Linux
   curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
   ```

1. Then, add it to your path:

   ```shell
   chmod +x ./minikube
   sudo mv ./minikube /usr/local/bin/
   ```

## Install a virtualization driver

Minikube requires virtualization. Install the appropriate driver for your operation system: [MacOS](https://github.com/kubernetes/minikube/blob/master/docs/drivers.md#hyperkit-driver) or [Linux](https://github.com/kubernetes/minikube/blob/master/docs/drivers.md#kvm2-driver).

## Starting Minikube

**Note:** If you are using a network filter such as [LittleSnitch](https://www.obdev.at/products/littlesnitch/index.html) you may need to disable it or permit `minikube`, as minikube needs to download multiple ISO's to operate correctly.

Continue with the steps under [First time setup](doc/howto/prometheus/minikube_usage.md#first-time-setup) to run minikube for use with GDK.
