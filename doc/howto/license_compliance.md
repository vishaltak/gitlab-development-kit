# License Compliance

To enable the License Compliance feature, populate the licenses dropdown.

Licenses come from the backend and are updated through a CRON job. Run the following to populate the licenses:

```shell
./bin/rails runner 'ImportSoftwareLicensesWorker.new.perform'
