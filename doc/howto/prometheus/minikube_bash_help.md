# Shell Methods for Minikube

1. Copy and paste the following scripts into your bash profile.
1. Update `$WORKSPACE` to the value for your local setup. Linux users, update the value for vm-driver to `kvm2` in the `mini-new` function.
1. Save the file and restart your terminal.
1. Note that all of the commands found below are independent - they do not rely on one another. Take whichever you like!

```shell
# Defines parent directory for cloned gdks; wherever gdk-ee and gdk-ce live
# Ex) export WORKSPACE="$HOME/gitlab-repos"
export WORKSPACE="REPLACE ME"

# Prints the available minikube shell commands to the console.
mini-help () {
  echo "
    mini-new <machine-name>                            | Delete and recreate a new minikube machine with the provided
                                                         name. Handles RBAC. Starts the minikube dashboard.
    mini-start <machine-name>                          | Starts (or restarts) the specified machine.
    mini-backup <machine-name> <optional backup-name>  | Copies the specified machine configuration to be restored later
                                                         if needed. A name for the backup can be provided, otherwise a
                                                         default is used.
    mini-restore <machine-name> <optional backup-name> | Restores the specified machine to the named backup if provided.
                                                         Otherwise uses the default backup.
    mini-stop <machine-name>                           | Stops the specified machine.
    mini-list                                          | Lists all machines.
    update-ip <ce||ee>                                 | Updates gitlab.yml to point to the current ip address. Requires
                                                         the WORKSPACE env variable to be set and the argument to
                                                         correspond to the edition of your gdk directory (likely named
                                                         gdk-ee or gdk-ce, so argument should be either ee or ce).
    open-url <ce||ee>                                  | Opens the running url for the specified environment. Arguments
                                                         should be either ce or ee.
    mini-help                                          | Lists the GitLab minikube commands available.

    Other helpful commands:
      minikube start --logtostderr
      kubectl get pods --namespace gitlab-managed-apps
      kubectl get pods --all-namespaces
      kubectl logs --namespace gitlab-managed-apps <pod-name>
  "
}


# -------- Interactions with Minikube --------------

# Delete and recreate a new minikube cluster of the specified name. Handles RBAC.
mini-new () {
  # Remove existing minikube machine to ensure a clean start
  minikube delete --profile $1

  # For Linux users or alternate vm drivers, replace "hyperkit" with the
  # appropriate value in the line below:
  minikube start --vm-driver=hyperkit --disk-size=20g --profile $1

  # Disable RBAC
  kubectl create clusterrolebinding permissive-binding \
    --clusterrole=cluster-admin \
    --user=admin \
    --user=kubelet \
    --group=system:serviceaccounts

  printf "\n\n\nCluster address:\nhttps://`minikube ip --profile $1`:8443\n\n\n"
  minikube dashboard --profile $1
}

# Start an existing minikube cluster
mini-start () {
  minikube stop --profile $1
  minikube start --profile $1

  printf "\n\n\nCluster address:\nhttps://`minikube ip --profile $1`:8443\n\n\n"
}

# Copies the specified machine configuration to be restored later if needed. A name for the backup can be provided, otherwise a default is used.
mini-backup () {
  local backup_name=${2:-"default_backup"}
  local backup_directory="$HOME/.minikube/machines/$1.$backup_name"
  local machine_directory="$HOME/.minikube/machines/$1"

  if [ ! $1 ]; then
    echo "The machine to backup must be specified"
    return 1
  fi

  if [ ! -d "$machine_directory" ]; then
    echo "The machine $1 could not be found at $machine_directory"
    return 1
  fi

  minikube stop -p $1

  if [ -d "$backup_directory" ]; then
    echo "Removing existing backup."
    rm -rf $backup_directory
  fi

  echo "Storing backup of $1 at $backup_directory..."
  cp -R $machine_directory $backup_directory
  echo "Backup stored."
}

# Restores the specified machine to the named backup if provided. Otherwise uses the default backup.
mini-restore() {
  local backup_name=${2:-"default_backup"}
  local backup_directory="$HOME/.minikube/machines/$1.$backup_name"
  local machine_directory="$HOME/.minikube/machines/$1"

  if [ ! $1 ]; then
    echo "A machine to restore must be specified"
  fi

  if [ ! -d "$backup_directory" ]; then
    echo "A backup machine for $1 could not be found at $backup_directory"
    return 1
  fi

  if [ -d "$machine_directory" ]; then
    minikube stop -p $1
    echo "Removing existing machine configuration."
    rm -rf $machine_directory
  fi

  echo "Restoring $1 from backup at $backup_directory..."
  cp -R $backup_directory $machine_directory
  echo "Restored."
}

# Stops the specified minikube cluster
mini-stop () {
  minikube stop --profile $1
}

# List all existing minikube machines.
mini-list () {
  ls ~/.minikube/machines
}


# --------- IP Config and URLs ---------------

# Opens the UI for the provided environment; Input should be either ce or ee
open-url () {
   [[ $1 = "ce" ]] && port="3000" || port="3001"
  open "http://$(ipconfig getifaddr en0):$port/"
}

# Set the ip address in the gitlab.yml host file
update-ip () {
  local filepath=$WORKSPACE/gdk-$1/gitlab/config/gitlab.yml
  awk '!x{
    cmd = "ipconfig getifaddr en0"
    cmd | getline new_ip
    close(cmd)
    new_host=sprintf("host: %s # updated to current ip from localhost", new_ip)
    x=sub(/host:.+/,new_host)
  }7' $filepath > tmp.yml && mv tmp.yml $filepath
  echo "The host in $filepath has been updated to `ipconfig getifaddr en0`."
}

```
