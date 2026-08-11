# Copyright 2026
# license that can be found in the LICENSE file.

##@ Common. License

common/license/check: ## Check that all files with extension have license head 
	@##~ EXTENSION_TO_CHECK=EXT - extension for find files for check. Required.
	@##~                            Should not contains leading * and dot (.).
	@##~                            For example: go
	@##~ ONLY_IN_SUB_DIR=PATH   - If passed will find files in passed sub-path 
	@##~                            as $(CURDIR)/ONLY_IN_SUB_DIR 
	@##~                            By default, find in $(CURDIR)
	@##~ COMMENT_PREFIX=PREFIX  - If passed check next strings with this prefix
	@##~                              Copyright YEAR
	@##~                              license that can be found in the LICENSE file.
	@##~                            If not passed, should pass FULL_COMMENT_STR
	@##~ FULL_COMMENT_STR=REGEX - If passed check split string by new line
	@##~                            and add each line to grep multiline pattern
	@##~                            Each line can be regexp with escape special symbols.
	@##~                            If not passed should pass COMMENT_PREFIX
	@##~ SKIP_FILES=PATHS       - comma separated paths without ext for skip checking.
	@##~                          Optional
	@##~ ONLY_CHANGED_WITH=REF  - git ref to check diff. If passed get diff from current and passed ref
	@##~                          and check files that changed between current and passed ref.
	@##~                          Optional
	@${INCLUDE_FS_CONSUME} \
	${INCLUDE_GIT_OPS} \
	if [ -z "$$EXTENSION_TO_CHECK" ]; then \
		exit_with_err "EXTENSION_TO_CHECK not passed"; \
	fi; \
	if [ -z "$$COMMENT_PREFIX" ] && [ -z "$$FULL_COMMENT_STR" ]; then \
		exit_with_err "COMMENT_PREFIX or FULL_COMMENT_STR not passed"; \
	fi; \
	skip_files_arr=(); \
	if [ -n "$$SKIP_FILES" ]; then \
		split_by_comma "skip_files_arr" "$$SKIP_FILES" "trim_spaces"; \
	fi; \
	grep_pat=""; \
	custom_grep_lines=(); \
	if [ -n "$$FULL_COMMENT_STR" ]; then \
		split_by_new_line "custom_grep_lines" "$$FULL_COMMENT_STR"; \
		for custom_line in "$${custom_grep_lines[@]}"; do \
			if [ -z "$$grep_pat" ]; then \
				grep_pat="$$custom_line"; \
				continue; \
			fi; \
			grep_pat="$${grep_pat}\\n$${custom_line}"; \
		done; \
	fi; \
	if [ -n "$$COMMENT_PREFIX" ]; then \
		grep_pat="$${COMMENT_PREFIX}\\s*Copyright \\d{4}\\n$${COMMENT_PREFIX}\\s*license that can be found in the LICENSE file."; \
	fi; \
	if [ -z "$$grep_pat" ]; then \
		exit_with_err "grep pattern is empty"; \
	fi; \
	function check_license() { \
		local fl="$${1:-}"; \
		local pat="$${2:-}"; \
		if [ -z "$$fl" ] && [ -z "$$pat" ]; then \
			echo_err "file to check and pattern is empty"; \
			return 1; \
		fi; \
		if [[ "$${#skip_files_arr[@]}" != "0" ]]; then \
			for skp_check in "$${skip_files_arr[@]}"; do \
				if [[ "$$fl" == *"$$skp_check"*."$$EXTENSION_TO_CHECK" ]]; then \
					echo "Skip '$$fl' by '$$skp_check'"; \
					return 0; \
				fi; \
			done; \
		fi; \
		if ! grep -Pzq "$$pat" "$$fl"; then \
			echo "License comment not found in '$$fl'"; \
			return 255; \
		fi; \
		return 0; \
	}; \
	sub_dir=""; \
	if [ -n "$$ONLY_IN_SUB_DIR" ]; then \
		sub_dir="$${ONLY_IN_SUB_DIR}/"; \
	fi; \
	if [ -n "$$ONLY_CHANGED_WITH" ]; then \
		diffed_files_str=""; \
		pat_to_check=".+\\.$${EXTENSION_TO_CHECK}"; \
		if [ -n "$$sub_dir" ]; then \
			escaped_sub_dir="$$(escape_re_str "$$sub_dir")"; \
			pat_to_check=".*$${escaped_sub_dir}$${pat_to_check}"; \
		fi; \
		if diffed_files_str="$$(get_git_changed_files "true" "$$pat_to_check" "" "$$ONLY_CHANGED_WITH")"; then \
			exit 0; \
		else \
			ret_code="$$?"; \
			if [[ "$$ret_code" == "255" ]]; then \
				exit_with_err "Has internal error ^^^"; \
			fi; \
		fi; \
		diffed_files=(); \
		split_by "$(GET_GIT_FILES_SEPARATOR)" "diffed_files" "$$diffed_files_str"; \
		files_without_license_out=""; \
		echo_fun="echo_info"; \
		exit_code="0"; \
		lines_sep=$$'\n'; \
		lines_sep="$${lines_sep}  "; \
		for chn_f in "$${diffed_files[@]}"; do \
			cur_out=""; \
			if ! cur_out="$$(check_license "$$chn_f" "$$grep_pat")"; then \
				echo_fun="echo_err"; \
				exit_code="1"; \
			fi; \
			files_without_license_out="$$(append_str_with_separator "$$lines_sep" "$$files_without_license_out" "$$cur_out")"; \
		done; \
		if [[ "$$exit_code" != 0 ]]; then \
			echo_err "Error while check:"; \
		fi; \
		if [ -n "$$files_without_license_out" ]; then \
			"$$echo_fun" "  $$files_without_license_out"; \
		fi; \
		exit "$$exit_code"; \
	fi; \
	files_glob="./$${sub_dir}**/*.$${EXTENSION_TO_CHECK}"; \
	out=""; \
	if ! out="$$(foreach_dir_by_glob "" "$$files_glob" "check_license" "$$grep_pat")"; then \
		echo_err "Error while check:"; \
		out="$$(shift_str_on "$$out" "2" " ")"; \
		echo_err "$$out"; \
		exit 1; \
	fi; \
	if [ -n "$$out" ]; then \
		echo_info "$$out"; \
	fi