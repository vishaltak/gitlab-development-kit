.PHONY: asdf-update
asdf-update: asdf-update-timed

.PHONY: asdf-update-run
asdf-update-run:
ifdef ASDF
ifeq ($(asdf_opt_out),false)
	@support/asdf-update
else
	$(Q)echo "INFO: asdf installed but asdf.opt_out is set to true"
	@true
endif
else
	@true
endif
