# Minikube Usage at GitLab

**Disclaimer**: minikube is finicky, but with the help of a few shell scripts and diligently following these workflows, the resource can be reliable. While we have both Community Edition and Enterprise Edition, the easiest way to manage minikube locally is to set up multiple machines - one for each edition. If you prefer not to use these scripts, all instructions include manual alternatives.

## First time setup:

The first time setup instructions assume that you are setting up a minikube machine called `ce` for Community Edition. If you want to call your machine something else, feel free.

### Option 1) Using shell scripts (recommended)

1. [Add the minikube scripts to your bash profile](doc/howto/prometheus/minikube_bash_help.md).

1. Using minikube requires us to configure GDK with the real IP address of your computer. This is because GDK returns this information to the Runner, and if it is wrong, pipelines will fail. To do this, run:

  ```shell
  update-ip ce
  ```
  Note: `update-ip` accepts only the arguments of `ce` or `ee`.

1. Configure GDK to listen to more than localhost.

  From the GDK root directory, create a host file to configure GDK to listen for more than just localhost. This will allow the Runner to connect to your GDK instance:

  ```shell
  echo 0.0.0.0 > host
  ```

1. To setup and start a new cluster with the appropriate configuration, run:

    ```shell
    mini-new ce
    ```
    The kubernetes dashboard for the cluster will open in your browser once the machine has been successfully setup. Take note of the "Cluster address" in the output. You'll want this for the next step.

    If you think there's a problem with the minikube machine at this stage, start debugging by trying `mini-new ce` again. It will delete and recreate the machine from scratch.

1. The previous step should have given us everything required to move to the GitLab UI! Continue with the [promtheus integration instructions](doc/howto/prometheus.md). Afterwards, [stop your machine](#daily-workflow), then [backup your minikube machine](#backups-restoration) to protect yourself from needing to complete this process again.

### Option 2) Manual configuration

#### IP Config

Using minikube requires us to configure GDK with real IP address of your computer. This is because GDK returns this information to the Runner, and if it is wrong, pipelines will fail.

1. Get your local IP address by running `ifconfig` or opening up Network Settings if on macOS. On Linux you can also use `ip addr show`.
1. Open `gitlab/config/gitlab.yml` and change the `host: localhost` line to reflect the IP of the previous step.
1. Save the file and restart GDK to apply this change.

You should now be able to access GitLab by the external URL (e.g., `http://192.168.1.1` not `localhost`), otherwise it may not work correctly.

#### Configure GDK to listen to more than localhost

From the GDK root directory, create a host file to configure GDK to listen for more than just localhost. This will allow the Runner to connect to your GDK instance:

```shell
echo 0.0.0.0 > host
```

#### Start Minikube

The following command will start minikube, running the first few containers with Kubernetes components. Note the `--profile <name>` at the end of the command. Whichever name you use here can be used to refer to this machine again later. If the `--profile` flag is left off, the machine will have the default name `minikube`.

For MacOS:

```shell
minikube start --vm-driver hyperkit --disk-size=20g --profile ce
```

For Linux:

```shell
minikube start --vm-driver kvm2 --disk-size=20g --profile ce
```

#### Open the Minikube Dashboard

Once Minikube starts, open the Kubernetes dashboard to ensure things are working. You can use this for future troubleshooting.

```shell
minikube dashboard --profile ce
```

#### Disable RBAC

AutoDevOps and Kubernetes app deployments do not yet support RBAC. To disable RBAC in your cluster, run the following command:

```shell
kubectl create clusterrolebinding permissive-binding \
  --clusterrole=cluster-admin \
  --user=admin \
  --user=kubelet \
  --group=system:serviceaccounts
```

#### Next Steps

You should now be ready to move to the GitLab UI! Continue with the [prometheus integration instructions](doc/howto/prometheus.md). Afterwards, [stop your machine](#daily-workflow), then [backup your minikube machine](#backups-restoration) to protect yourself from needing to complete this process again.


## Daily workflow:

1. If you're in a different location from last time you ran GDK, run:

  ```shell
  update-ip <ce||ee>
  ```
  Note: `update-ip` accepts only the arguments of `ce` or `ee`.

  For manual instructions on updating gitlab.yml with your IP address, refer back to [First time setup](#first-time-setup).

1. Start your machine:

  ```shell
  mini-start <machine-name>
  ```

  Alternate option: `minikube start --profile <machine-name>`

1. When you're done working with minikube (or shutting down/putting your computer to sleep), stop your minikube machine:

  ```shell
  mini-stop <machine-name>
  ```

  Alternate option: `minikube stop --profile <machine-name>`


## Backups & Restoration

Backups are simply copies of existing machines. However, we can take advantage of this to quickly reset a machine to a time when it was working correctly.

### Option 1) Using shell scripts (recommended)

#### List existing backups

All minikube machines are stored in `~/.minikube/machines`.

```shell
mini-list
```
lists the contents of the above directory, like so:

```
ce  ee  ce.default_backup  server-key.pem  server.pem
```

In this example, I have machines corresponding to Community Edition (`ce`) and Enterprise Edition (`ee`), and then one machine I've copied in case of future issues with `ce` (`ce.default_backup`).

#### Backing up your machine

**Disclaimer**: If you don't already have a backup and your machine is corrupted, you'll need to delete the machine and create a new one. `mini-new <machine-name>` will accomplish that, but you'll still want to install any utilities you need through the UI.

To save a backup of your machine, run:

```shell
mini-backup <machine-name>
```

Note that this will stop the machine. If you need to keep using it, simply start it back up with `mini-start <machine-name>`.

Optional: If you want to backup machines in several different states, you can provide an additional argument to `mini-backup` to save the machine under a different name. For example:

```shell
mini-backup ce only_helm_installed
```

will save a backup to `ce.only_helm_installed`

#### Restoring from a backup

To restore a machine from the default backup (assuming you've previously created one), run:

```shell
mini-restore <machine-name>
```

Optional: If you want to restore from a particular backup machine, provide the machine identifier as an argument to `mini-restore`, like:

```shell
mini-restore ce only_helm_installed
```

This will restore your machine named `ce` to the machine called `ce.only_helm_installed`.

### Option 2) Manual Configuration

#### List existing backups

All minikube machines are stored in `~/.minikube/machines`.

```shell
ls ~/.minikube/machines
```
lists the contents of the above directory, like so:

```
ce  ee  ce.prometheus_installed  server-key.pem  server.pem
```

In this example, I have machines corresponding to Community Edition (`ce`) and Enterprise Edition (`ee`), and then one machine I've copied in case of future issues with `ce` (`ce.prometheus_installed`).


#### Backing up your machine

**Disclaimer**: If you don't already have a backup and your machine is corrupted, you'll need to delete the machine and create a new one. `minikube delete --profile <machine-name>` will delete the machine. Refer to [First time setup](#first-time-setup) for help recreating the machine with the correct configuration. Afterwards, you'll still want to install any utilities you need through the UI.

Save a backup of your machine using:

```shell
minikube stop --profile <machine-name> && cp -R ~/.minikube/machines/<machine-name> ~/.minikube/machines/<backup-machine-name>
```

Note that this will stop the machine. If you need to keep using it, simply start it back up with `minikube start --profile <machine-name>`.

#### Restoring from a backup

To restore a machine from a backup, run:

```shell
cp -R ~/.minikube/machines/<backup-machine-name> ~/.minikube/machines/<machine-name>
```

## Minikube commands cheatsheat

```
mini-new <machine-name>                            | Delete and recreate a new minikube machine with the provided name. Handles RBAC. Starts the minikube dashboard.
mini-start <machine-name>                          | Starts (or restarts) the specified machine.
mini-backup <machine-name> <optional backup-name>  | Copies the specified machine configuration to be restored later if needed. A name for the backup can be provided, otherwise a default is used.
mini-restore <machine-name> <optional backup-name> | Restores the specified machine to the named backup if provided. Otherwise uses the default backup.
mini-stop <machine-name>                           | Stops the specified machine.
mini-list                                          | Lists all machines.
update-ip <ce||ee>                                 | Updates gitlab.yml to point to the current ip address. Requires the WORKSPACE env variable to be set and the argument to correspond to the edition of your gdk directory (likely named gdk-ee or gdk-ce, so argument should be either ee or ce).
open-url <ce||ee>                                  | Opens the running url for the specified environment. Arguments should be either ce or ee.
mini-help                                          | Lists the GitLab minikube commands available.
```
