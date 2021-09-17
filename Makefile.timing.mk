.PHONY: %-timed
%-timed:
	@make $(*F)-timing-start $(*F)-run $(*F)-timing-end

.PHONY: %-timing-start
%-timing-start:
	@support/dev/makefile-timeit time-service-start $(*F)

.PHONY: %-timing-end
%-timing-end:
	@support/dev/makefile-timeit time-service-end $(*F)
