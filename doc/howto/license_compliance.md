# License Compliance

## Populate licenses dropdown

To enable the License Compliance feature, populate the licenses dropdown.
Licenses come from the backend and are updated through a CRON job. Run the following to populate the licenses:

```shell
./bin/rails runner 'ImportSoftwareLicensesWorker.new.perform'
```

## Enable license scanning

To enable the License Scanning feature:

1. Populate the licenses dropdown in [the Admin panel](https://docs.gitlab.com/ee/administration/settings/security_and_compliance.html#choose-package-registry-metadata-to-sync). 
1. Add `export PM_SYNC_IN_DEV=true` to your [`env.runit` file](../runit.md#modifying-environment-configuration-for-services).
1. Licenses come from the external license database and are stored in the GitLab database. They are updated through a CRON job. Run the following to populate your local GitLab database immediately: 

   ```shell
   ./bin/rails runner 'PackageMetadata::LicensesSyncWorker.perform_async'
   ```
