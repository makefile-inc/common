# Copyright 2026
# license that can be found in the LICENSE file.

##@ Common. Git

GET_GIT_FILES_SEPARATOR = |||

# INCLUDE_GIT_OPS - add next sh functions:
#   is_git_repo_has_not_changes - returns 1 if git repo has diff (uncommit changes).
#     Returns 255 code if has internal error. 
#   get_git_changed_files - returns 1 and echo list of files have changes in one string separated by $(GET_GIT_FILES_SEPARATOR) 
#     Returns 255 code if has internal error.
#     Returns zero code if git repo has not changes.
#     Arguments:
#       $1 - if passed "true" also new files will returned
#       $2 - comma-separated grep patterns files to check diff. Optional 
#            otherwise check all files.
#       $3 - comma-separated grep patterns files to skip check diff. Optional 
#            otherwise check all files.
# Example include:
#   @${INCLUDE_GIT_OPS} \ - slash is required!
# Example:
#   include *.mk
#   repo-has-diff:
#		@${INCLUDE_GIT_OPS} \
#		if ! is_git_repo_has_not_changes; then \
#			exit 1; \
#		fi;
#   echo-has-diff:
#		@${INCLUDE_GIT_OPS} \
#		diffed_files_str=""; \
#		if diffed_files_str="$$(get_git_changed_files "$$with_new_files" "$$files_check" "$$files_skip")"; then \
#			exit 0; \
#		else \
#			ret_code="$$?"; \
#			if [[ "$$ret_code" == "255" ]]; then \
#				exit_with_err "Has internal error ^^^"; \
#			fi; \
#		fi; \
#		diffed_files=(); \
#		split_by "$(GET_GIT_FILES_SEPARATOR)" "diffed_files" "$$diffed_files_str"; \
#		msg="$${HAS_DIFF_MSG:-}"; \
#		if [ -n "$$msg" ]; then \
#			exit_with_err "$$msg"; \
#		fi; \
#		echo_err "Files changed:"; \
#		for chn_f in "$${diffed_files[@]}"; do \
#			echo_err "  $$chn_f"; \
#		done; \
#		exit 1
# Can be included multiple times because sh redeclare function without error
define INCLUDE_GIT_OPS
${INCLUDE_ECHO} \
${INCLUDE_STRINGS} \
function is_git_repo_has_not_changes() { \
	local stt=""; \
	if ! stt="$$(git status)"; then \
		echo_err "Cannot get repo status with 'git status'"; \
		return 255; \
	fi; \
	if ! grep -q "nothing to commit, working tree clean" <<<"$$stt"; then \
		echo_err "Git status:"; \
		echo "$$stt"; \
		echo_err "Git repo has changes"; \
		return 1; \
	fi; \
	return 0; \
}; \
__git_diff_patterns_for_check_arr=(); \
__git_diff_patterns_for_skip_arr=(); \
function get_git_changed_files() { \
	__git_diff_patterns_for_check_arr=(); \
	__git_diff_patterns_for_skip_arr=(); \
    local include_new="$${1:-}"; \
    local files_check="$${2:-}"; \
	local files_skip="$${3:-}"; \
	if [ -n "$$files_check" ]; then \
		split_by_comma "__git_diff_patterns_for_check_arr" "$$files_check" "trim_spaces"; \
	fi; \
	if [ -n "$$files_skip" ]; then \
		split_by_comma "__git_diff_patterns_for_skip_arr" "$$files_skip" "trim_spaces"; \
	fi; \
	local output=""; \
	if ! output="$$(git diff --name-status)"; then \
		echo_err "cannot run git diff"; \
		return 255; \
	fi; \
	local new_output=""; \
	if [[ "$$include_new" == "true" ]]; then \
		if ! new_output="$$(git ls-files --others --exclude-standard)"; then \
			echo_err "cannot run git ls-files --others --exclude-standard"; \
			return 255; \
		fi; \
	fi; \
	if [ -z "$$output" ] && [ -z "$$new_output" ]; then \
		return 0; \
	fi; \
	if [ -n "$$output" ]; then \
		if ! output="$$(cut -f 2 <<<"$$output")"; then \
			echo_err "cannot run cut for output"; \
			return 255; \
		fi; \
		if ! output="$$(sort <<<"$$output")"; then \
			echo_err "cannot run sort for output"; \
			return 255; \
		fi; \
		local files=(); \
		while IFS= read -r fl; do \
			files+=("$$fl"); \
		done <<<"$$output"; \
		local changed=(); \
		for fl_a in "$${files[@]}"; do \
			local skipped=""; \
			for skp in "$${__git_diff_patterns_for_skip_arr[@]}"; do \
				if grep -qE "$$skp" <<<"$$fl_a"; then \
					skipped="true"; \
					break; \
				fi; \
			done; \
			if [ -n "$$skipped" ]; then \
				echo_info "$$fl_a skipped"; \
				continue; \
			fi; \
			if [ "$${#__git_diff_patterns_for_check_arr[@]}" -eq 0 ]; then \
				changed+=("$$fl_a"); \
				continue; \
			fi; \
			local file_changed=""; \
			for chn in "$${__git_diff_patterns_for_check_arr[@]}"; do \
				if grep -qE "$$chn" <<<"$$fl_a"; then \
					file_changed="true"; \
					break; \
				fi; \
			done; \
			if [ -n "$$file_changed" ]; then \
				changed+=("$$fl_a"); \
			else \
				echo_info "$$fl_a skipped"; \
			fi; \
		done; \
	fi; \
	if [ -n "$$new_output" ]; then \
		for new_f in $$new_output; do \
			changed+=("$$new_f"); \
		done; \
	fi; \
	if [ "$${#changed[@]}" -eq 0 ]; then \
		return 0; \
	fi; \
	local res_files=""; \
	for chn_f in "$${changed[@]}"; do \
		res_files="$$(append_str_with_separator "$(GET_GIT_FILES_SEPARATOR)" "$$res_files" "$$chn_f")"; \
	done; \
	echo -n "$$res_files"; \
	return 1; \
};
endef

common/git/check/no-changes: ## Check that git repo has not changes across all repo.
	@${INCLUDE_GIT_OPS} \
	if ! is_git_repo_has_not_changes; then \
		exit 1; \
	fi;

common/git/check/gitignore: ## Check that gitignore file contains another gitignore files rules.
	@##~ ROOT_GITIGNORE=PATH - path to gitignore file for check. Default $(CURDIR)/.gitignore
	@##~ GITIGNORES_WITH_REQUIRED_RULES=PATHS... - comma separated paths to gitignore files that should contains ROOT_GITIGNORE
	@${INCLUDE_SPLIT} \
	${INCLUDE_ECHO} \
	root_gitignore="$$ROOT_GITIGNORE"; \
	if [ -z "$$root_gitignore" ]; then \
		root_gitignore="$(CURDIR)/.gitignore"; \
	fi; \
	if [ ! -f "$$root_gitignore" ]; then \
		exit_with_err "$$root_gitignore not found or not file"; \
	fi; \
	if [ -z "$$GITIGNORES_WITH_REQUIRED_RULES" ]; then \
		exit_with_err "GITIGNORES_WITH_REQUIRED_RULES with comma separated gitignore's to check not passed"; \
	fi; \
	echo_info "Use root .gitignore as $$root_gitignore"; \
	split_by_comma "gitignores_list" "$$GITIGNORES_WITH_REQUIRED_RULES" "trim_spaces"; \
	if [[ "$${#gitignores_list[@]}" == "0" ]]; then \
		exit_with_err "GITIGNORES_WITH_REQUIRED_RULES have empty list"; \
	fi; \
	function correct_gitignore_line() { \
		local line="$$1"; \
		if [ -z "$$line" ]; then \
			return 1; \
		fi; \
		local spaces_re="^[[:space]]+$$"; \
		if [[ "$$line" =~ $$spaces_re ]]; then \
			return 1; \
		fi; \
		if grep -q "^#" <<<"$$line"; then \
			return 1; \
		fi; \
		return 0; \
	}; \
	lines_in_root=(); \
	while IFS= read -r root_line; do \
    	if correct_gitignore_line "$$root_line"; then \
			lines_in_root+=("$$root_line"); \
		fi; \
	done < "$$root_gitignore"; \
	not_have=(); \
	for cur_gitignore in "$${gitignores_list[@]}"; do \
		if [ ! -f "$$cur_gitignore" ]; then \
			not_have+=("$$cur_gitignore is not file"); \
			continue; \
		fi; \
		while IFS= read -r file_line; do \
    		if ! correct_gitignore_line "$$file_line"; then \
				continue; \
			fi; \
			consumed_cur=""; \
			for cur_from_root in "$${lines_in_root[@]}"; do \
				if [[ "$$cur_from_root" == "$$file_line" ]]; then \
					consumed_cur="true"; \
					break; \
				fi; \
			done; \
			if [ -z "$$consumed_cur" ]; then \
				not_have+=("File $$root_gitignore does not contains line '$$file_line' from file '$$cur_gitignore'"); \
			fi; \
		done < "$$cur_gitignore"; \
	done; \
	if [[ "$${#not_have[@]}" == "0" ]]; then \
		exit 0; \
	fi; \
	echo_err "Root gitignore $$root_gitignore not have:"; \
	for err in "$${not_have[@]}"; do \
		echo_err "  $$err"; \
	done; \
	exit 1

common/git/check/has-diff: ## Check diff in repo
	@##~ TARGET_NAME=NAME - if passed run make target before git diff check
	@##~ HAS_DIFF_MSG=MSG - if has diff this message will be printed. Optional
	@##~ FILES_TO_CHECK=REGEXPS... - comma separated paths regexp for check. Optional
	@##~ FILES_TO_SKIP=REGEXPS...  - comma separated paths regexp for skip. Optional
	@##~ SKIP_NEW_FILES=true       - if FILES_TO_CHECK and FILES_TO_SKIP not passed
	@##~                             target will out new files to diff. If passed new files will not 
	@##~                             If passed, new files will not include to diff 
	@${INCLUDE_GIT_OPS} \
	set -Eeuo pipefail; \
	target_name="$${TARGET_NAME:-}"; \
	if [ -n "$$target_name" ]; then \
		echo_info "Run '$$target_name'..."; \
		if ! $(MAKE) "$$target_name"; then \
			exit_with_err "$$target_name was failed" 2; \
		fi; \
	fi; \
	files_check="$${FILES_TO_CHECK:-}"; \
	files_skip="$${FILES_TO_SKIP:-}"; \
	with_new_files="true"; \
	if [ -n "$${SKIP_NEW_FILES:-}" ] || [ -n "$$files_check" ] || [ -n "$$files_skip" ]; then \
		with_new_files=""; \
	fi; \
	diffed_files_str=""; \
	if diffed_files_str="$$(get_git_changed_files "$$with_new_files" "$$files_check" "$$files_skip")"; then \
		exit 0; \
	else \
		ret_code="$$?"; \
		if [[ "$$ret_code" == "255" ]]; then \
			exit_with_err "Has internal error ^^^"; \
		fi; \
	fi; \
	diffed_files=(); \
	split_by "$(GET_GIT_FILES_SEPARATOR)" "diffed_files" "$$diffed_files_str"; \
	msg="$${HAS_DIFF_MSG:-}"; \
	if [ -n "$$msg" ]; then \
		exit_with_err "$$msg"; \
	fi; \
	echo_err "Files changed:"; \
	for chn_f in "$${diffed_files[@]}"; do \
		echo_err "  $$chn_f"; \
	done; \
	exit 1

.PHONY: common/git/check/gitignore common/git/check/has-diff common/git/check/no-changes