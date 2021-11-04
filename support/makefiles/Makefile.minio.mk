.PHONY: object-storage-setup
ifeq ($(object_storage_enabled),true)
object-storage-setup: minio/data/lfs-objects minio/data/artifacts minio/data/uploads minio/data/packages minio/data/terraform minio/data/pages minio/data/external-diffs
	@true
else
object-storage-setup:
	@true
endif

.PHONY: object-storage-update
ifeq ($(object_storage_enabled),true)
object-storage-update: object-storage-setup
else
object-storage-update:
	@true
endif

minio/data/%:
	$(Q)mkdir -p $@
