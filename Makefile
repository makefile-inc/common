include *.mk

_test/common/duration:
	@start="$$(${NOW_MICROSECONDS})"; \
	sleep 2; \
	end="$$(${NOW_MICROSECONDS})"; \
	dur="$$(${HUMAN_DURATION_MICROSECONDS} "$$start" "$$end")"; \
	echo "Duration $$dur"

_test/common/duration/micros:
	@start="1781528292578192"; \
	end="1781528292579192"; \
	dur="$$(${HUMAN_DURATION_MICROSECONDS} "$$start" "$$end")"; \
	echo "Duration $$dur"

_test/common/duration/seconds:
	@start="1781528292578192"; \
	end="1781528293579295"; \
	dur="$$(${HUMAN_DURATION_MICROSECONDS} "$$start" "$$end")"; \
	echo "Duration $$dur"

_test/common/duration/minutes:
	@start="1781528292578192"; \
	end="1781528393579295"; \
	dur="$$(${HUMAN_DURATION_MICROSECONDS} "$$start" "$$end")"; \
	echo "Duration $$dur"

_test/common/duration/hours:
	@start="1781528292578192"; \
	end="1781628393579295"; \
	dur="$$(${HUMAN_DURATION_MICROSECONDS} "$$start" "$$end")"; \
	echo "Duration $$dur"

_test/common/sleep-exec-ok:
	@sleep 2; \
	echo "Do ok"; \
	exit 0

_test/common/sleep-exec-fail:
	@sleep 2; \
	echo "Do fail"; \
	exit 3

_test/common/cleanup/run:
	@echo "Do cleanup"

_test/common/run-with-duration/ok:
	@${RUN_WITH_DURATION} "_test/common/sleep-exec-ok" "Do with ok"

_test/common/run-with-duration/fail:
	@${RUN_WITH_DURATION} "_test/common/sleep-exec-fail" "Do with fail"

_test/common/run-with-cleanup/ok:
	@$(call RUN_WITH_CLEANUP,_test/common/sleep-exec-ok,_test/common/cleanup/run)

_test/common/run-with-cleanup/fail:
	@$(call RUN_WITH_CLEANUP,_test/common/sleep-exec-fail,_test/common/cleanup/run)

_test/common/all: _test/common/duration _test/common/duration/micros _test/common/duration/seconds _test/common/duration/minutes _test/common/duration/hours _test/common/run-with-duration/ok _test/common/run-with-cleanup/ok