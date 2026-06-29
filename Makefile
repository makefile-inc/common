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

_test/build/default/project-env: export PROJECT_NAME = my
_test/build/default/project-env:
	@set -e; \
	${INCLUDE_BUILD_OUT_NAME} \
	bin_name="$$(build_out_name)"; \
	echo "Project env: $$bin_name"

_test/build/project-arch-env: export PROJECT_NAME = my1
_test/build/project-arch-env: export BUILD_ARCH = $(ARCH_ARM)
_test/build/project-arch-env:
	@set -e; \
	${INCLUDE_BUILD_OUT_NAME} \
	bin_name="$$(build_out_name)"; \
	echo "Project arch env: $$bin_name"

_test/build/project-arch-platform-env: export PROJECT_NAME = my1
_test/build/project-arch-platform-env: export BUILD_ARCH = $(ARCH_ARM)
_test/build/project-arch-platform-env: export BUILD_OS = $(OS_MACOS)
_test/build/project-arch-platform-env:
	@set -e; \
	${INCLUDE_BUILD_OUT_NAME} \
	bin_name="$$(build_out_name)"; \
	echo "Project platform arch env: $$bin_name"

_test/build/pass-project:
	@set -e; \
	${INCLUDE_BUILD_OUT_NAME} \
	bin_name="$$(build_out_name "passed")"; \
	echo "Pass project: $$bin_name"

_test/build/pass-project-platform:
	@set -e; \
	${INCLUDE_BUILD_OUT_NAME} \
	bin_name="$$(build_out_name "passed2" "$(OS_MACOS)")"; \
	echo "Pass project platform: $$bin_name"

_test/build/pass-project-platform-arch:
	@set -e; \
	${INCLUDE_BUILD_OUT_NAME} \
	bin_name="$$(build_out_name "passed3" "$(OS_MACOS)" "$(ARCH_ARM)")"; \
	echo "Pass project platform arch: $$bin_name"

_test/build/incorrect/platform-env: export PROJECT_NAME = my3
_test/build/incorrect/platform-env: export BUILD_ARCH = $(ARCH_ARM)
_test/build/incorrect/platform-env: export BUILD_OS = "incorrect"
_test/build/incorrect/platform-env:
	@set -e; \
	${INCLUDE_BUILD_OUT_NAME} \
	bin_name="$$(build_out_name)"; \
	echo "Pass project platform arch: $$bin_name"

_test/build/incorrect/platform:
	@set -e; \
	${INCLUDE_BUILD_OUT_NAME} \
	bin_name="$$(build_out_name "passed4" "incorrect" "$(ARCH_ARM)")"; \
	echo "Pass project platform arch: $$bin_name"

_test/build/incorrect/arch-env: export PROJECT_NAME = my4
_test/build/incorrect/arch-env: export BUILD_ARCH = "incorrect"
_test/build/incorrect/arch-env: export BUILD_OS = $(OS_MACOS)
_test/build/incorrect/arch-env:
	@set -e; \
	${INCLUDE_BUILD_OUT_NAME} \
	bin_name="$$(build_out_name)"; \
	echo "Pass project platform incorrect arch: $$bin_name"

_test/build/incorrect/arch:
	@set -e; \
	${INCLUDE_BUILD_OUT_NAME} \
	bin_name="$$(build_out_name "passed3" "$(OS_MACOS)" "incorrect")"; \
	echo "Pass project platform arch incorrect: $$bin_name"

_test/build/no-project:
	@set -e; \
	${INCLUDE_BUILD_OUT_NAME} \
	bin_name="$$(build_out_name)"; \
	echo "No project: $$bin_name"

_test/build/target/ok:
	@sleep 1; \
	echo "Build finished: out=$$OUT_BIN; os=$$BUILD_OS; arch=$$BUILD_ARCH"

_test/build/target/fail:
	@sleep 1; \
	echo "Build failed: out=$$OUT_BIN; os=$$BUILD_OS; arch=$$BUILD_ARCH"; \
	exit 3

_test/build/bin/current: export PROJECT_NAME=bu1
_test/build/bin/current: export BUILD_TARGET=_test/build/target/ok
_test/build/bin/current: build/current

_test/build/bin/linux: export PROJECT_NAME=bu2
_test/build/bin/linux: export BUILD_TARGET=_test/build/target/ok
_test/build/bin/linux: build/linux

_test/build/bin/linux/all: export PROJECT_NAME=bu3
_test/build/bin/linux/all: export BUILD_TARGET=_test/build/target/ok
_test/build/bin/linux/all: build/linux/all

_test/build/bin/mac: export PROJECT_NAME=bu4
_test/build/bin/mac: export BUILD_TARGET=_test/build/target/ok
_test/build/bin/mac: build/mac

_test/build/bin/mac/all: export PROJECT_NAME=bu4
_test/build/bin/mac/all: export BUILD_TARGET=_test/build/target/ok
_test/build/bin/mac/all: build/mac/all

_test/build/bin/all: export PROJECT_NAME=bu5
_test/build/bin/all: export BUILD_TARGET=_test/build/target/ok
_test/build/bin/all: build/all

_test/build/bin/fail: export PROJECT_NAME=bu-fail
_test/build/bin/fail: export BUILD_TARGET=_test/build/target/fail
_test/build/bin/fail: build/all

_test/common/all/build: _test/build/bin/current _test/build/bin/linux _test/build/bin/linux/all _test/build/bin/mac _test/build/bin/mac/all _test/build/bin/all

_test/common/all: _test/common/duration _test/common/duration/micros _test/common/duration/seconds _test/common/duration/minutes _test/common/duration/hours _test/common/run-with-duration/ok _test/common/run-with-cleanup/ok

_test/build/all: _test/build/default/project-env _test/build/project-arch-env _test/build/project-arch-platform-env _test/build/pass-project _test/build/pass-project-platform _test/build/pass-project-platform-arch

_test/common/all/fail:
	@if $(MAKE) _test/common/run-with-duration/fail; then \
		echo "_test/common/run-with-duration/fail should fail"; \
		exit 1; \
	fi; \
	if $(MAKE) _test/common/run-with-cleanup/fail; then \
		echo "_test/common/run-with-cleanup/fail should fail"; \
		exit 1; \
	fi; \

_test/build/all/fail:
	@if $(MAKE) _test/build/incorrect/platform-env; then \
		echo "_test/build/incorrect/platform-env should fail"; \
		exit 1; \
	fi; \
	if $(MAKE) _test/build/incorrect/platform; then \
		echo "_test/build/incorrect/platform should fail"; \
		exit 1; \
	fi; \
	if $(MAKE) _test/build/incorrect/arch-env; then \
		echo "_test/build/incorrect/arch-env should fail"; \
		exit 1; \
	fi; \
	if $(MAKE) _test/build/incorrect/arch; then \
		echo "_test/build/incorrect/arch should fail"; \
		exit 1; \
	fi; \
	if $(MAKE) _test/build/no-project; then \
		echo "_test/build/no-project should fail"; \
		exit 1; \
	fi; \
	if $(MAKE) _test/build/bin/fail; then \
		echo "_test/build/bin/fail should fail"; \
		exit 1; \
	fi;

_test/echo:
	@${INCLUDE_ECHO} \
	echo_info "Done"; \
	echo_warn "Warn"; \
	echo_err "Error!"; \
	${INCLUDE_ECHO} \
	echo_info "After second include"

_test/all: _test/echo _test/common/all _test/build/all _test/common/all/build _test/common/all/fail _test/build/all/fail