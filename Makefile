include *.mk

_test/install/common: install/jq install/yq
	@$(MAKE) install/jq
	@$(MAKE) install/yq

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

_test/build/default/project-env: export PROJECT_NAME = project-env
_test/build/default/project-env:
	@set -e; \
	${INCLUDE_BUILD_OUT_NAME} \
	bin_name="$$(build_out_name)"; \
	echo "Project env: $$bin_name"

_test/build/project-arch-env: export PROJECT_NAME = project-arch-env
_test/build/project-arch-env: export BUILD_ARCH = $(ARCH_ARM)
_test/build/project-arch-env:
	@set -e; \
	${INCLUDE_BUILD_OUT_NAME} \
	bin_name="$$(build_out_name)"; \
	echo "Project arch env: $$bin_name"

_test/build/project-arch-os-env: export PROJECT_NAME = project-arch-os-env
_test/build/project-arch-os-env: export BUILD_ARCH = $(ARCH_ARM)
_test/build/project-arch-os-env: export BUILD_OS = $(OS_MACOS)
_test/build/project-arch-os-env:
	@set -e; \
	${INCLUDE_BUILD_OUT_NAME} \
	bin_name="$$(build_out_name)"; \
	echo "Project platform arch env: $$bin_name"

_test/build/pass-project:
	@set -e; \
	${INCLUDE_BUILD_OUT_NAME} \
	bin_name="$$(build_out_name "passed-project")"; \
	echo "Pass project: $$bin_name"

_test/build/pass-project-platform:
	@set -e; \
	${INCLUDE_BUILD_OUT_NAME} \
	bin_name="$$(build_out_name "passed-project-platform" "$(OS_MACOS)")"; \
	echo "Pass project platform: $$bin_name"

_test/build/pass-project-platform-arch:
	@set -e; \
	${INCLUDE_BUILD_OUT_NAME} \
	bin_name="$$(build_out_name "passed-project-platform-arch" "$(OS_MACOS)" "$(ARCH_ARM)")"; \
	echo "Pass project platform arch: $$bin_name"

_test/build/incorrect/os-env: export PROJECT_NAME = incorrect-platform-env
_test/build/incorrect/os-env: export BUILD_ARCH = $(ARCH_ARM)
_test/build/incorrect/os-env: export BUILD_OS = "incorrect"
_test/build/incorrect/os-env:
	@set -e; \
	${INCLUDE_BUILD_OUT_NAME} \
	bin_name="$$(build_out_name)"; \
	echo "Pass project platform arch: $$bin_name"

_test/build/incorrect/os:
	@set -e; \
	${INCLUDE_BUILD_OUT_NAME} \
	bin_name="$$(build_out_name "incorrect-passed-os" "incorrect-os" "$(ARCH_ARM)")"; \
	echo "Pass project platform arch: $$bin_name"

_test/build/incorrect/arch-env: export PROJECT_NAME = incorrect-arch-env
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
	bin_name="$$(build_out_name "passed-incorrect-arch" "$(OS_MACOS)" "incorrect")"; \
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

_test/build/bin/current: export PROJECT_NAME=build-current
_test/build/bin/current: export BUILD_TARGET=_test/build/target/ok
_test/build/bin/current: build/current

_test/build/bin/linux: export PROJECT_NAME=build-linux
_test/build/bin/linux: export BUILD_TARGET=_test/build/target/ok
_test/build/bin/linux: build/linux

_test/build/bin/linux/all: export PROJECT_NAME=build-linux-all
_test/build/bin/linux/all: export BUILD_TARGET=_test/build/target/ok
_test/build/bin/linux/all: build/linux/all

_test/build/bin/mac: export PROJECT_NAME=build-mac
_test/build/bin/mac: export BUILD_TARGET=_test/build/target/ok
_test/build/bin/mac: build/mac

_test/build/bin/mac/all: export PROJECT_NAME=build-mac-all
_test/build/bin/mac/all: export BUILD_TARGET=_test/build/target/ok
_test/build/bin/mac/all: build/mac/all

_test/build/bin/all: export PROJECT_NAME=build-all
_test/build/bin/all: export BUILD_TARGET=_test/build/target/ok
_test/build/bin/all: build/all

_test/build/bin/fail: export PROJECT_NAME=build-fail
_test/build/bin/fail: export BUILD_TARGET=_test/build/target/fail
_test/build/bin/fail: build/all

_test/common/all/build: _test/build/bin/current _test/build/bin/linux _test/build/bin/linux/all _test/build/bin/mac _test/build/bin/mac/all _test/build/bin/all

_test/common/all: _test/common/duration _test/common/duration/micros _test/common/duration/seconds _test/common/duration/minutes _test/common/duration/hours _test/common/run-with-duration/ok _test/common/run-with-cleanup/ok

_test/build/all: _test/build/default/project-env _test/build/project-arch-env _test/build/project-arch-os-env _test/build/pass-project _test/build/pass-project-platform _test/build/pass-project-platform-arch

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
	@if $(MAKE) _test/build/incorrect/os-env; then \
		echo "_test/build/incorrect/os-env should fail"; \
		exit 1; \
	fi; \
	if $(MAKE) _test/build/incorrect/os; then \
		echo "_test/build/incorrect/os should fail"; \
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

_test/split:
	@${INCLUDE_SPLIT} \
	function print_arr() { \
		local function_array=("$$@"); \
    	for item in "$${function_array[@]}"; do \
        	echo "Value: '$$item'"; \
    	done; \
	}; \
	comma="a,b c,d"; \
	split_by_comma "comma_arr" "$$comma"; \
	echo "Comma-separated:"; \
	print_arr "$${comma_arr[@]}"; \
	new_line=$$'Hello with\n Name'; \
	split_by_new_line "new_line_arr" "$$new_line"; \
	echo "New line-separated:"; \
	print_arr "$${new_line_arr[@]}"; \
	spaces=$$'val ba bbval\nccc'; \
	split_by_space "spaces_arr" "$$spaces"; \
	echo "Spaces-separated:"; \
	print_arr "$${spaces_arr[@]}"; \
	own=$$'val ba. bbval\nccc'; \
	split_by '.' "own_arr" "$$own"; \
	echo "Dot-separated:"; \
	print_arr "$${own_arr[@]}"; \
	multi=$$'val ba\n b|||bval|||ccc'; \
	split_by '|||' "multi_arr" "$$multi"; \
	echo "Multi-separated:"; \
	print_arr "$${multi_arr[@]}"

_test/trim:
	@${INCLUDE_SPLIT} \
	b="$$(trim_spaces $$'\n  \t\n\t   from begin')"; \
	e="$$(trim_spaces $$'from end\n  \t\n\t  ')"; \
	m="$$(trim_spaces $$'\n  \t\n\tin middle\n  \t\n\t  ')"; \
	n="$$(trim_spaces "no trim")"; \
	echo "'$$b'";\
	echo "'$$e'";\
	echo "'$$m'";\
	echo "'$$n'"

_test/clean: clean/common clean/build

_test/all: _test/echo _test/install/common _test/common/all _test/build/all _test/common/all/build _test/common/all/fail _test/build/all/fail _test/split _test/trim _test/clean