# AWS EKS Authentication

Within the AWS test account, there is a `gitlab-local-user` IAM user which has
programmatic access to assume any role whose name ends with `-local-provision-role`.

You will need the account ID, access key ID, and secret access key which can be
found in the GitLab Team 1password vault.

## Enable EKS Integration

To enable the EKS integration within your GKE instance, follow the same [steps
outlined for self-managed instances](https://docs.gitlab.com/ee/user/project/clusters/add_remove_clusters.html#additional-requirements-for-self-managed-instances) and use the
`AWS gitlab-local-user` credentials found within 1Password. You do not need
to create your own IAM user.

## Authenticating with AWS EKS

To authenticate with AWS EKS, you first must create a provision role. Follow step 4 under
[Creating the cluster on EKS](https://docs.gitlab.com/ee/user/project/clusters/add_remove_clusters.html#creating-the-cluster-on-eks)
and use the following:

1. Under policy, choose `gitlab-local-role-policy`.
1. Format your role name as follows: `[name]-local-provision-role` with `[name]` being
your `gitlab.com` handle.
