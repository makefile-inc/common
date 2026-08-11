# Copyright 2026
# license that can be found in the LICENSE file.

# INCLUDE_FS_CONSUME - add next sh functions:
#   toggle_globs - enable/disable next globs params "dotglob" "nullglob" "globstar"
#     Returns 255 code if error 
#     Arguments:
#       $1 - if "on" - enable globs, otherwise - disable
#   is_glob - check passed string is glob string
#     Returns non-zero if not glob
#     Arguments:
#       $1 - string to check
#   do_in_dir - cd to dir and do function, after call returns to current dir.
#     Function output will output as result of function.
#     Returns 255 code if has internal error
#     Otherwise, returns return code from function.
#     Arguments:
#       $1  - dir to cd
#       $2  - function to call
#       ... - another arguments will passed to function started from second arg, first argument is dir path
#   foreach_dir_by_glob - call function for each file found by glob.
#     Returns 255 exit code if has internal error.
#     Warning! if you need to find all files in dir and sub dirs
#     pass glob with prefix ./**/
#     Passed function can return next return codes:
#       255 - will continue foreach, but foreach_dir_by_glob returns 1 return code.
#             Useful if need fail, but check all files. 
#       254 - will continue foreach, but foreach_dir_by_glob returns zero return code.
#             Useful if need skip some files. 
#       [1-253] - immediately return from function with returned error code
#     Warning! globs is enabled due to call function. 
#     Arguments:
#       $1  - if passes non empty string, will cd to directory and returns to current dir after call
#       $2  - glob to find files
#       $3  - function to call
#       ... - another arguments will passed to function started from second arg, first argument is file path  
# Example include:
#   @${INCLUDE_FS_CONSUME} \ - slash is required!
# Example:
#   include *.mk
#   _test/glob:
#		@${INCLUDE_FS_CONSUME} \
#		if is_glob "*.c?p"; then \
#			echo "Is glob!"; \
#		fi; \
#		if ! is_glob "./app"; then \
#			echo "Is not glob!"; \
#		fi
#
#   _test/fs-utils: _test/glob
#		$(MAKE) install/jq
#		@${INCLUDE_FS_CONSUME} \
#		function echo_file_with_prefix() { \
#			if [[ "$${1}" != "00-common.mk" ]]; then \
#				echo "[$${2}] Find file $${1}"; \
#				return 0; \
#			fi; \
#			return 254; \
#		}; \
#		function echo_file_with_prefix_fail() { \
#			if [[ "$${1}" != "00-common.mk" ]]; then \
#				echo "[$${2}] Find fail file $${1}"; \
#				return 0; \
#			fi; \
#			return 255; \
#		}; \
#		function echo_file_with_prefix_fail_fast() { \
#			if [[ "$${1}" != "03-versions.mk" ]]; then \
#				echo "[$${2}] Find file $${1}"; \
#				return 0; \
#			fi; \
#			echo_err "found fail fast file!"; \
#			return 1; \
#		}; \
#		if foreach_dir_by_glob "" "*.mk" echo_file_with_prefix "ok"; then \
#			echo ""; \
#			echo_info "foreach_dir_by_glob ok!"; \
#		fi; \
#		echo ""; \
#		if ! foreach_dir_by_glob "" "*.mk" echo_file_with_prefix_fail "fail"; then \
#			echo ""; \
#			echo_info "foreach_dir_by_glob failed!"; \
#		fi; \
#		echo ""; \
#		if ! foreach_dir_by_glob "" "*.mk" echo_file_with_prefix_fail_fast; then \
#			echo ""; \
#			echo_info "foreach_dir_by_glob failed fast!"; \
#		fi; \
#		echo ""; \
#		function ls_dir_ok() { \
#			echo "ls dir $${1}:"; \
#			if ! ls -lh "$${1}"; then \
#				echo_warn "ls failed but skipped"; \
#			fi; \
#			return 0; \
#		}; \
#		function ls_dir_fail_with_prefix() { \
#			echo "[$${2}] ls dir fail $${1}:"; \
#			if ! ls -lh "$${1}"; then \
#				echo_warn "ls failed but skipped"; \
#			fi; \
#			echo "error return"; \
#			return 1; \
#		}; \
#		if do_in_dir "$(BINARIES_PATH)" ls_dir_ok; then \
#			echo ""; \
#			echo_info "do_in_dir ok!"; \
#		fi; \
#		if ! do_in_dir "$(BINARIES_PATH)" ls_dir_fail_with_prefix "fail prefix"; then \
#			echo ""; \
#			echo_info "do_in_dir failed!"; \
#		fi
# Can be included multiple times because sh redeclare function without error
define INCLUDE_FS_CONSUME
${INCLUDE_ECHO} \
${INCLUDE_STRINGS} \
function toggle_globs() { \
	local shop_arg="-u"; \
	local err_msg="disable globs"; \
	if [[ "$${1:-}" == "on" ]]; then \
		shop_arg="-s"; \
		err_msg="enable globs"; \
	fi; \
	local globs_sett=("dotglob" "nullglob" "globstar"); \
	for g_sett in "$${globs_sett[@]}"; do \
		if ! shopt $$shop_arg "$$g_sett"; then \
			echo_err "Cannot $$err_msg $$g_sett"; \
			return 255; \
		fi; \
	done; \
	return 0; \
}; \
function is_glob() { \
	if [[ "$$1{:-}" =~ [*?\[] ]]; then \
		return 0; \
	fi; \
	return 1; \
}; \
function do_in_dir() { \
    local dir_to_do="$${1:-}"; \
    local to_do_func="$${2:-}"; \
	shift; \
	shift; \
	if [ -z "$$dir_to_do" ]; then \
		echo_err "dir_to_do not passed as first arg"; \
		return 255; \
	fi; \
	if [ -z "$$to_do_func" ]; then \
		echo_err "to_do_func not passed as second arg"; \
		return 255; \
	fi; \
	if ! declare -F "$$to_do_func" > /dev/null; then \
    	echo_err "$$to_do_func function is not declared"; \
		return 255; \
	fi; \
	if ! pushd . > /dev/null; then \
		echo_err "cannot pushd cur dir"; \
		return 255; \
	fi; \
	if ! cd "$$dir_to_do"; then \
		echo_err "cannot cd to '$$dir_to_do'"; \
		if ! popd > /dev/null; then \
			echo_err "cannot popd"; \
		fi; \
		return 255; \
	fi; \
	local ret_code="255"; \
	local do_out=""; \
	if do_out="$$("$$to_do_func" "$$dir_to_do" "$$@")"; then \
		ret_code="0"; \
	else \
		ret_code="$$?"; \
	fi; \
	if ! popd > /dev/null; then \
		echo_err "cannot popd"; \
		return 255; \
	fi; \
	echo -n "$$do_out"; \
	return "$$ret_code"; \
}; \
function foreach_dir_by_glob() { \
    local dir_to_do="$${1:-}"; \
    local glob_str="$${2:-}"; \
    local to_do_func="$${3:-}"; \
	shift; \
	shift; \
	shift; \
	need_cd="true"; \
	if [ -z "$$dir_to_do" ]; then \
		need_cd=""; \
	fi; \
	if [ -z "$$glob_str" ]; then \
		echo_err "glob_str not passed as second arg"; \
		return 255; \
	fi; \
	if ! is_glob "$$glob_str"; then \
		echo_err "$$glob_str is not glob"; \
		return 255; \
	fi; \
	if [ -z "$$to_do_func" ]; then \
		echo_err "to_do_func not passed as third arg"; \
		return 255; \
	fi; \
	if ! declare -F "$$to_do_func" > /dev/null; then \
    	echo_err "$$to_do_func function is not declared"; \
		return 255; \
	fi; \
	if [[ "$$need_cd" == "true" ]]; then \
		if ! pushd . > /dev/null; then \
			echo_err "cannot pushd cur dir"; \
			return 255; \
		fi; \
		if ! cd "$$dir_to_do"; then \
			echo_err "cannot cd to '$$dir_to_do'"; \
			if ! popd > /dev/null; then \
				echo_err "cannot popd"; \
			fi; \
			return 255; \
		fi; \
	fi; \
	toggle_globs "on"; \
	local ret_code=""; \
	local do_out=""; \
	local new_line=$$'\n'; \
	for fl in $$glob_str; do \
		local cur_ret_code="255"; \
		local cur_out=""; \
		if cur_out="$$("$$to_do_func" "$$fl" "$$@")"; then \
			if [ -z "$$ret_code" ]; then \
				ret_code="0"; \
			fi; \
			do_out="$$(append_str_with_new_line "$$do_out" "$$cur_out")"; \
		else \
			cur_ret_code="$$?"; \
			do_out="$$(append_str_with_new_line "$$do_out" "$$cur_out")"; \
			if [[ "$$cur_ret_code" == "254" ]]; then \
				ret_code="0"; \
				echo_warn "Command '$$to_do_func' failed with file '$$fl' but continue without fail all"; \
				continue; \
			elif [[ "$$cur_ret_code" == "255" ]]; then \
				ret_code="1"; \
				echo_warn "Command '$$to_do_func' failed with file '$$fl' but continue with fail all"; \
				continue; \
			else \
				ret_code="$$cur_ret_code"; \
				echo_err "Command '$$to_do_func' failed with file '$$fl' with code $$ret_code Exit"; \
				break; \
			fi; \
		fi; \
	done; \
	toggle_globs; \
	if [[ "$$need_cd" == "true" ]]; then \
		if ! popd > /dev/null; then \
			echo_err "cannot popd"; \
			return 255; \
		fi; \
	fi; \
	echo -n "$$do_out"; \
	return "$$ret_code"; \
};
endef
