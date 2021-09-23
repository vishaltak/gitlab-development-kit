.PHONY: object-storage-update
object-storage-update: object-storage-update-timed

.PHONY: object-storage-update-run
object-storage-update-run: object-storage-setup

object-storage-setup: minio/data/lfs-objects minio/data/artifacts minio/data/uploads minio/data/packages minio/data/terraform minio/data/pages minio/data/external-diffs

minio/data/%:
	$(Q)mkdir -p $@
