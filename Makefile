include *.mk

DUMMY_BIN = dummy
DUMMY_FULL_BIN = $(BINARIES_PATH)/$(DUMMY_BIN)

_test/install/dummy: export INSTALL_BIN_NAME = $(DUMMY_BIN)
_test/install/dummy: export INSTALL_BIN_VERSION_ARG = ver
_test/install/dummy: export INSTALL_BIN_VERSION = 0.0.1
_test/install/dummy:
	@function get_dummy() { \
		local ver="$$1"; \
		local arch="$$2"; \
		local os="$$3"; \
		local name="$$4"; \
		local dest="$$5"; \
		local pt="$$6"; \
    	{ \
        	echo -n "#"; \
        	echo '!/usr/bin/env bash'; \
			echo 'if [[ $$1 == "ver" ]]; then'; \
			echo -n '  echo "'; \
			echo -n "name=$$name; path=$$pt; arch=$$arch; os=$$os; v$$ver"; \
			echo '"'; \
			echo 'fi'; \
    	} > "$$dest"; \
	}; \
	${INCLUDE_CHECK_BINARY} \
	if ! check_and_get_bin get_dummy; then \
		exit 1; \
	fi; \
	if [ ! -x "$(DUMMY_FULL_BIN)" ]; then \
		exit_with_err "$(DUMMY_FULL_BIN) is not executable"; \
	fi

_clean/dummy:
	@rm -fv "$(DUMMY_FULL_BIN)"

_test/install/common: install/jq install/yq _test/install/dummy
	@$(MAKE) install/jq
	@$(MAKE) install/yq
	@$(MAKE) _test/install/dummy

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
_test/build/bin/current: common/build/current

_test/build/bin/linux: export PROJECT_NAME=build-linux
_test/build/bin/linux: export BUILD_TARGET=_test/build/target/ok
_test/build/bin/linux: common/build/linux

_test/build/bin/linux/all: export PROJECT_NAME=build-linux-all
_test/build/bin/linux/all: export BUILD_TARGET=_test/build/target/ok
_test/build/bin/linux/all: common/build/linux/all

_test/build/bin/mac: export PROJECT_NAME=build-mac
_test/build/bin/mac: export BUILD_TARGET=_test/build/target/ok
_test/build/bin/mac: common/build/mac

_test/build/bin/mac/all: export PROJECT_NAME=build-mac-all
_test/build/bin/mac/all: export BUILD_TARGET=_test/build/target/ok
_test/build/bin/mac/all: common/build/mac/all

_test/build/bin/all: export PROJECT_NAME=build-all
_test/build/bin/all: export BUILD_TARGET=_test/build/target/ok
_test/build/bin/all: common/build/all

_test/build/bin/fail: export PROJECT_NAME=build-fail
_test/build/bin/fail: export BUILD_TARGET=_test/build/target/fail
_test/build/bin/fail: common/build/all

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

_test/dynamic/ok: check/installed/curl
	@export TARGET_BIN_TO_CHECK="$$(command -v curl)"; \
	$(MAKE) check/bin/linked/dynamic

_test/dynamic/fail: check/installed/curl
	@export TARGET_BIN_TO_CHECK="$$(command -v curl)"; \
	if $(MAKE) build/check/bin/static; then \
		echo "check/bin/linked/static for curl should fail"; \
		exit 1; \
	fi

_test/executable: _test/dynamic/ok _test/dynamic/fail

_RELEASE_EXEC_PROJECT = release-exec
_RELEASE_DIR_PROJECT = release-dir
_RELEASE_DIR_PATH = $(BUILD_PATH)/bundle
_RELEASE_ARTIFACTS_DIR = $(BUILD_PATH)/.artifacts

_test/release/prepare/artifacts:
	@$(MAKE) common/build/dir; \
	mkdir -p "$(_RELEASE_ARTIFACTS_DIR)"; \
	mkdir -p "$(_RELEASE_ARTIFACTS_DIR)/sub"; \
	mkdir -p "$(_RELEASE_ARTIFACTS_DIR)/sub/deep"; \
	echo "readme" > "$(_RELEASE_ARTIFACTS_DIR)/README.md"; \
	echo "license" > "$(_RELEASE_ARTIFACTS_DIR)/LICENSE"; \
	echo "ignore" > "$(_RELEASE_ARTIFACTS_DIR)/.ignore"; \
	echo "first" > "$(_RELEASE_ARTIFACTS_DIR)/sub/first.txt"; \
	echo "second" > "$(_RELEASE_ARTIFACTS_DIR)/sub/second.txt"; \
	echo "third" > "$(_RELEASE_ARTIFACTS_DIR)/sub/deep/third.txt"; \

_test/release/prepare/exec:
	@${INCLUDE_BUILD_OUT_NAME} \
	$(MAKE) common/build/dir; \
	amd="$$(build_out_name "$(_RELEASE_EXEC_PROJECT)" "$(OS_LINUX)" "$(ARCH_AMD)")"; \
	arm="$$(build_out_name "$(_RELEASE_EXEC_PROJECT)" "$(OS_LINUX)" "$(ARCH_ARM)")"; \
	amd_full="$(BUILD_PATH)/$${amd}"; \
	arm_full="$(BUILD_PATH)/$${arm}"; \
	echo "echo amd" > "$$amd_full"; \
	echo "echo arm" > "$$arm_full"; \
	chmod 755  "$$amd_full"; \
	chmod 755  "$$arm_full"

_test/release/prepare/dir:
	@${INCLUDE_BUILD_OUT_NAME} \
	$(MAKE) common/build/dir; \
	amd="$$(build_out_name "$(_RELEASE_DIR_PROJECT)" "$(OS_LINUX)" "$(ARCH_AMD)")"; \
	arm="$$(build_out_name "$(_RELEASE_DIR_PROJECT)" "$(OS_LINUX)" "$(ARCH_ARM)")"; \
	amd_full="$(_RELEASE_DIR_PATH)/$${amd}"; \
	arm_full="$(_RELEASE_DIR_PATH)/$${arm}"; \
	for ii in "$$amd_full" "$$arm_full"; do \
		mkdir -p "$$ii"; \
		mkdir -p "$${ii}/.dot"; \
		mkdir -p "$${ii}/sb"; \
		mkdir -p "$${ii}/sb/deep"; \
		echo "index" > "$${ii}/index.js"; \
		chmod 755 "$${ii}/index.js"; \
		echo "ignore" > "$${ii}/.ignore"; \
		echo "aa" > "$${ii}/.dot/aa.txt"; \
		echo "another" > "$${ii}/sb/another"; \
		echo "modules" > "$${ii}/sb/deep/modules"; \
		echo "track" > "$${ii}/sb/deep/.track"; \
	done

_test/release/exec: export RELEASE_NAME = v0.0.1
_test/release/exec: export PROJECT_NAME = $(_RELEASE_EXEC_PROJECT)
_test/release/exec:
	@$(MAKE) clean/build; \
	$(MAKE) clean/release; \
	$(MAKE) _test/release/prepare/exec; \
	$(MAKE) common/release; \

_test/release/exec/artifacts: export RELEASE_NAME = v0.0.2
_test/release/exec/artifacts: export PROJECT_NAME = $(_RELEASE_EXEC_PROJECT)
_test/release/exec/artifacts: export ADDITIONAL_ARTIFACTS_DIR = $(_RELEASE_ARTIFACTS_DIR)
_test/release/exec/artifacts:
	@$(MAKE) clean/build; \
	$(MAKE) clean/release; \
	$(MAKE) _test/release/prepare/exec; \
	$(MAKE) _test/release/prepare/artifacts; \
	$(MAKE) common/release; \


_test/release/dir: export RELEASE_NAME = v0.0.3
_test/release/dir: export PROJECT_NAME = $(_RELEASE_DIR_PROJECT)
_test/release/dir: export BINARIES_DIR = $(_RELEASE_DIR_PATH)
_test/release/dir:
	@$(MAKE) clean/build; \
	$(MAKE) clean/release; \
	$(MAKE) _test/release/prepare/dir; \
	$(MAKE) common/release; \

_test/release/dir/artifact: export RELEASE_NAME = v0.0.4
_test/release/dir/artifact: export PROJECT_NAME = $(_RELEASE_DIR_PROJECT)
_test/release/dir/artifact: export BINARIES_DIR = $(_RELEASE_DIR_PATH)
_test/release/dir/artifact: export ADDITIONAL_ARTIFACTS_DIR = $(_RELEASE_ARTIFACTS_DIR)
_test/release/dir/artifact:
	@$(MAKE) clean/build; \
	$(MAKE) clean/release; \
	$(MAKE) _test/release/prepare/dir; \
	$(MAKE) _test/release/prepare/artifacts; \
	$(MAKE) common/release; \

_test/release: _test/release/exec _test/release/exec/artifacts _test/release/dir _test/release/dir/artifact

_test/split:
	@${INCLUDE_SPLIT} \
	${INCLUDE_ECHO} \
	echo_info "split tests:"; \
	function print_arr() { \
		local function_array=("$$@"); \
		if [ "$${#function_array[@]}" -eq 0 ]; then \
			echo "Got empty array"; \
			return; \
		fi; \
    	for item in "$${function_array[@]}"; do \
        	echo "Value: '$$item'"; \
    	done; \
	}; \
	function own_transform_fun() { \
		echo -n "transformed: '$${1:-}'"; \
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
	print_arr "$${multi_arr[@]}"; \
	empty=""; \
	split_by_comma "empty_arr" "$$empty"; \
	echo "Empty:"; \
	print_arr "$${empty_arr[@]}"; \
	trim_left=$$'a, b b,,  c,\n d ,e f,'; \
	split_by_comma "trim_left_arr" "$$trim_left" "trim_spaces_left"; \
	echo "Transform trim left:"; \
	print_arr "$${trim_left_arr[@]}"; \
	trim_right=$$'a ,b b ,  c  ,d \n,e f'; \
	split_by_comma "trim_right_arr" "$$trim_right" "trim_spaces_right"; \
	echo "Transform trim right:"; \
	print_arr "$${trim_right_arr[@]}"; \
	trim_all=$$' a , b b ,  c,\n d \n,e f,g '; \
	split_by_comma "trim_all_arr" "$$trim_all" "trim_spaces"; \
	echo "Transform trim all:"; \
	print_arr "$${trim_all_arr[@]}"; \
	trim_all_empty=""; \
	split_by_comma "trim_all_empty_arr" "$$trim_all_empty" "trim_spaces"; \
	echo "Transform trim all empty:"; \
	print_arr "$${trim_all_empty_arr[@]}"; \
	transform_own="a||b c|| de||g"; \
	split_by "||" "transform_own_arr" "$$transform_own" "own_transform_fun"; \
	echo "Transform own:"; \
	print_arr "$${transform_own_arr[@]}"

_test/trim:
	@${INCLUDE_SPLIT} \
	${INCLUDE_ECHO} \
	echo_info "trim tests:"; \
	b="$$(trim_spaces $$'\n  \t\n\t   from begin')"; \
	e="$$(trim_spaces $$'from end\n  \t\n\t  ')"; \
	m="$$(trim_spaces $$'\n  \t\n\tin middle\n  \t\n\t  ')"; \
	n="$$(trim_spaces "no trim")"; \
	echo "'$$b'";\
	echo "'$$e'";\
	echo "'$$m'";\
	echo "'$$n'"

_test/append-str-with:
	@${INCLUDE_STRINGS} \
	${INCLUDE_ECHO} \
	echo_info "append_str_with tests:"; \
	empty=""; \
	empty="$$(append_str_with_separator "|" "$$empty" "first")"; \
	echo "Empty after add first: '$$empty'"; \
	empty="$$(append_str_with_separator "|" "$$empty" "second")"; \
	echo "Empty after add second: '$$empty'"; \
	empty="$$(append_str_with_separator "|" "$$empty" "third")"; \
	echo "Empty after add third: '$$empty'"; \
	not_empty="not empty"; \
	not_empty="$$(append_str_with_separator " | " "$$not_empty" "first")"; \
	echo "Not empty after add first: '$$not_empty'"; \
	not_empty="$$(append_str_with_separator " | " "$$not_empty" "second")"; \
	echo "Not empty after add second: '$$not_empty'"; \
	not_empty="$$(append_str_with_separator " | " "$$not_empty" "third")"; \
	echo "Not empty after add third: '$$not_empty'"; \
	empty_with_empty_add=""; \
	empty_with_empty_add="$$(append_str_with_separator "; " "$$empty_with_empty_add" "")"; \
	echo "Empty with empty add - add empty string: '$$empty_with_empty_add'"; \
	empty_with_empty_add="$$(append_str_with_separator "; " "$$empty_with_empty_add" "first")"; \
	echo "Empty with empty add - after add first: '$$empty_with_empty_add'"; \
	empty_with_empty_add="$$(append_str_with_separator "; " "$$empty_with_empty_add" "")"; \
	echo "Empty with empty add - second empty: '$$empty_with_empty_add'"; \
	empty_with_empty_add="$$(append_str_with_separator "; " "$$empty_with_empty_add" "second")"; \
	echo "Empty with empty add - add second: '$$empty_with_empty_add'"; \
	append_new_line=""; \
	append_new_line="$$(append_str_with_new_line "$$append_new_line" "")"; \
	echo "Append with new line - add empty: '$$append_new_line'"; \
	append_new_line="$$(append_str_with_new_line "$$append_new_line" "first str")"; \
	echo "Append with new line - add first str: '$$append_new_line'"; \
	append_new_line="$$(append_str_with_new_line "$$append_new_line" "second str")"; \
	echo "Append with new line - add second str: '$$append_new_line'"

_test/shift-str-on:
	@${INCLUDE_STRINGS} \
	${INCLUDE_ECHO} \
	echo_info "shift_str_on tests:"; \
	new_line=$$'\n'; \
	one_string="one string"; \
	one_string="$$(shift_str_on "$$one_string" "5" " ")"; \
	echo "One string: '$$one_string'"; \
	two_strings="first string$${new_line}second string"; \
	two_strings="$$(shift_str_on "$$two_strings" "1" " - ")"; \
	echo "Two strings: '$$two_strings'"; \
	three_strings="first string$${new_line}second string$${new_line}third string"; \
	three_strings="$$(shift_str_on "$$three_strings" "1" "** ")"; \
	echo "three strings:"; \
	echo "$$three_strings"; \
	three_strings="$$(shift_str_on_tab "$$three_strings" "2")"; \
	echo "three strings after shift on 2 tabs:"; \
	echo "$$three_strings"

_test/str-utils: _test/trim _test/split _test/append-str-with _test/shift-str-on

_test/glob:
	@${INCLUDE_FS_CONSUME} \
	if is_glob "*.c?p"; then \
		echo "Is glob!"; \
	fi; \
	if ! is_glob "./app"; then \
		echo "Is not glob!"; \
	fi

_test/fs-utils: _test/glob
	$(MAKE) install/jq
	@${INCLUDE_FS_CONSUME} \
	function echo_file_with_prefix() { \
		if [[ "$${1}" != "00-common.mk" ]]; then \
			echo "[$${2}] Find file $${1}"; \
			return 0; \
		fi; \
		return 254; \
	}; \
	function echo_file_with_prefix_fail() { \
		if [[ "$${1}" != "00-common.mk" ]]; then \
			echo "[$${2}] Find fail file $${1}"; \
			return 0; \
		fi; \
		return 255; \
	}; \
	function echo_file_with_prefix_fail_fast() { \
		if [[ "$${1}" != "03-versions.mk" ]]; then \
			echo "[$${2}] Find file $${1}"; \
			return 0; \
		fi; \
		echo_err "found fail fast file!"; \
		return 1; \
	}; \
	if foreach_dir_by_glob "" "*.mk" echo_file_with_prefix "ok"; then \
		echo ""; \
		echo_info "foreach_dir_by_glob ok!"; \
	fi; \
	echo ""; \
	if ! foreach_dir_by_glob "" "*.mk" echo_file_with_prefix_fail "fail"; then \
		echo ""; \
		echo_info "foreach_dir_by_glob failed!"; \
	fi; \
	echo ""; \
	if ! foreach_dir_by_glob "" "*.mk" echo_file_with_prefix_fail_fast; then \
		echo ""; \
		echo_info "foreach_dir_by_glob failed fast!"; \
	fi; \
	echo ""; \
	function ls_dir_ok() { \
		echo "ls dir $${1}:"; \
		if ! ls -lh "$${1}"; then \
			echo_warn "ls failed but skipped"; \
		fi; \
		return 0; \
	}; \
	function ls_dir_fail_with_prefix() { \
		echo "[$${2}] ls dir fail $${1}:"; \
		if ! ls -lh "$${1}"; then \
			echo_warn "ls failed but skipped"; \
		fi; \
		echo "error return"; \
		return 1; \
	}; \
	if do_in_dir "$(BINARIES_PATH)" ls_dir_ok; then \
		echo ""; \
		echo_info "do_in_dir ok!"; \
	fi; \
	if ! do_in_dir "$(BINARIES_PATH)" ls_dir_fail_with_prefix "fail prefix"; then \
		echo ""; \
		echo_info "do_in_dir failed!"; \
	fi

_test/run/get-diff:
	@${INCLUDE_GIT_OPS} \
	diffed_files_str=""; \
	if diffed_files_str="$$(get_git_changed_files "$$INCLUDE_NEW" ".+\\.mk" "" "$$TARGET_REF")"; then \
		exit 0; \
	else \
		ret_code="$$?"; \
		if [[ "$$ret_code" == "255" ]]; then \
			exit_with_err "Has internal error ^^^"; \
		fi; \
	fi; \
	diffed_files=(); \
	split_by "$(GET_GIT_FILES_SEPARATOR)" "diffed_files" "$$diffed_files_str"; \
	for chn_f in "$${diffed_files[@]}"; do \
		echo_err "  $$chn_f"; \
	done; \

_test/get-diff:
	${INCLUDE_ECHO} \
	echo_warn "Only diff:"; \
	$(MAKE) _test/run/get-diff;\
	echo_warn "Diff with new:"; \
	$(MAKE) _test/run/get-diff INCLUDE_NEW=true;\
	echo_warn "Diff with main:"; \
	$(MAKE) _test/run/get-diff TARGET_REF=main

define FULL_COMMENT
# Copyright \d{4}
# license that can be found in the LICENSE file.
endef

_test/license/current: export EXTENSION_TO_CHECK = mk
_test/license/current: export COMMENT_PREFIX = \#
_test/license/current: 
	@$(MAKE) common/license/check

_test/license/current/full: export EXTENSION_TO_CHECK = mk
_test/license/current/full: export FULL_COMMENT_STR = ${FULL_COMMENT}
_test/license/current/full:
	@$(MAKE) common/license/check

_test/license: _test/license/current _test/license/current/full

_test/clean: clean/common clean/build clean/release _clean/dummy

_test/all: _test/echo _test/install/common _test/common/all _test/build/all _test/common/all/build _test/common/all/fail _test/build/all/fail _test/release _test/clean _test/executable _test/license _test/str-utils _test/fs-utils