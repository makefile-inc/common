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
#       $4 - get diff with passed git ref. Optional.
#            If not passed, do diff with current git repo state
# 	is_repo_detach_head - returns 0 ret code if repo has detach head (on tag or commit)
#	  Returns 255 code if has internal error (git status failed), 
#     otherwise repo has not detach head (on branch).
#	  Arguments: do not take any arguments
#	is_git_dir_submodule_dir - check is passed path is git submodule dir
# 	  Returns 0 if submodule, 1 otherwise not.
# 	  Returns 255 code if has internal error:
#       path not passed
#       path is absolute path
#       path contains parents (start with ..) 
#       path is not dir
#     Arguments:
#       $1 - dir for check
#	repo_has_submodules - check git repo (current dir) has submodules
# 	    Returns 0 if has submodules, 1 otherwise not.
# 	  Arguments: do not take any arguments
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
	local with_ref="$${4:-}"; \
	if [ -n "$$files_check" ]; then \
		split_by_comma "__git_diff_patterns_for_check_arr" "$$files_check" "trim_spaces"; \
	fi; \
	if [ -n "$$files_skip" ]; then \
		split_by_comma "__git_diff_patterns_for_skip_arr" "$$files_skip" "trim_spaces"; \
	fi; \
	local output=""; \
	if [ -z "$$with_ref" ]; then \
		if ! output="$$(git diff --name-status)"; then \
			echo_err "cannot run git diff"; \
			return 255; \
		fi; \
	else \
		if ! output="$$(git diff --name-status "$$with_ref")"; then \
			echo_err "cannot run git diff with ref $$with_ref"; \
			return 255; \
		fi; \
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
}; \
function is_repo_detach_head() { \
	local git_status=""; \
	if ! git_status="$$(git status)"; then \
		echo_error "Cannot get git status"; \
		return 255; \
	fi; \
	if [ -z "$$git_status" ]; then \
		echo_warn "Git status is empty. Returns not detach"; \
		return 0; \
	fi; \
	local detach_head_msg=""; \
	if detach_head_msg="$$(echo -n "$$git_status" | grep "HEAD detached at")"; then \
		echo_info "$$detach_head_msg"; \
		return 0; \
	fi; \
	return 1; \
}; \
function is_git_dir_submodule_dir() { \
	local dir_path="$${1:-}"; \
	if [ -z "$$dir_path" ]; then \
		echo_error "Dir path is not passed"; \
		return 255; \
	fi; \
	if [[ "$$dir_path" == /* ]]; then \
		echo_error "Dir '$$dir_path' is not relative"; \
		return 255; \
	fi; \
	if [[ "$$dir_path" == ..* ]]; then \
		echo_error "Dir '$$dir_path' has parent dir (start with ..)"; \
		return 255; \
	fi; \
	if [ ! -d "$$dir_path" ]; then \
		echo_error "Dir '$$dir_path' is not dir"; \
		return 255; \
	fi; \
	if [ ! -s "$${SUBMODULE_DIR}/.git" ]; then \
		return 1; \
	fi; \
	return 0; \
}; \
const_git_modules_dir=".git/modules"; \
function repo_has_submodules() { \
	if [ ! -f ".gitmodules" ]; then \
		return 1; \
	fi; \
	if [ ! -d "$$const_git_modules_dir" ]; then \
		return 1; \
	fi; \
	if dir_is_empty "$$const_git_modules_dir"; then \
		return 1; \
	fi; \
	return 0; \
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

common/git/check/has-diff: ## Check diff in repo and out diffed files
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

common/git/submodule/upgrade: ## Upgrade submodule to new ref or pull current branch
	@##~ SUBMODULE_DIR=PATH           - submodule dir path. Should relative without parents (..)
	@##~                                Required.
	@##~ CHECKOUT_TO=GIT_REF_OR_TAG   - if passed checkout to passed ref.
	@##~                                Otherwise, only pull of current if repo not of tag
	@##~                                (detach head)
	@##~ SKIP_UPGRADE_SUBMODULES=true - if passed do not upgrade recursive submodules in passed submodule.
	@##~                              - Optional.
	@${INCLUDE_GIT_OPS} \
	${INCLUDE_FS_CONSUME} \
	if ! repo_has_submodules; then \
		exit_with_err "Repo does not contains submodules"; \
	fi; \
	ret_code_is_sub_module="0"; \
	if is_git_dir_submodule_dir "$$SUBMODULE_DIR"; then \
		echo_info "Passed submodule dir '$$SUBMODULE_DIR'"; \
	else \
		ret_code_is_sub_module="$$?"; \
		if [[ "$$ret_code_is_sub_module" == "255" ]]; then \
			exit_with_err "SUBMODULE_DIR '$$SUBMODULE_DIR' incorrect"; \
		fi; \
		exit_with_err "SUBMODULE_DIR '$$SUBMODULE_DIR' is not submodule dir"; \
	fi; \
	function __upgrade_submodule() { \
		if ! git fetch -a; then \
			echo_error "Cannot git fetch -a"; \
			return 1; \
		fi; \
		if [ -n "$${CHECKOUT_TO:-}" ]; then \
			echo_info "Checkout submodule '$$SUBMODULE_DIR' to '$$CHECKOUT_TO' ref"; \
			if ! git checkout "$$CHECKOUT_TO"; then \
				echo_error "Cannot checkout submodule '$SUBMODULE_DIR' to '$$CHECKOUT_TO' ref"; \
				return 1; \
			fi; \
		else \
			local check_detach_ret_code="0"; \
			if is_repo_detach_head; then \
				echo_error "CHECKOUT_TO not passed and repo has detach head. Cannot run pull"; \
				return 1; \
			else \
				check_detach_ret_code="$$?"; \
				if [[ "$$check_detach_ret_code" == "255" ]]; then \
					echo_error "Cannot check repo has detach head"; \
					return 1; \
				fi; \
				if ! git pull; then \
					echo_error "Cannot run git pull"; \
					return 1; \
				fi;\
			fi; \
		fi; \
		if [ -z "$${SKIP_UPGRADE_SUBMODULES:-}" ]; then \
			echo_green "Update submodules in submodule recursive"; \
			if ! git submodule update --recursive; then \
				echo_error "Cannot update submodules in submodule '$$SUBMODULE_DIR'"; \
				return 1; \
			fi; \
		else \
			echo_warn "SKIP_UPGRADE_SUBMODULES passed. Skip update submodule in submodule '$$SUBMODULE_DIR'"; \
		fi; \
		return 0; \
	}; \
	do_in_submodule_ret_code="0"; \
	if do_in_dir "$$SUBMODULE_DIR" "__upgrade_submodule"; then \
		echo ""; \
		exit 0; \
	else \
		do_in_submodule_ret_code="$$?"; \
		err_msg="Cannot upgrade submodule"; \
		if [[ "$$do_in_submodule_ret_code" == "255" ]]; then \
			err_msg="$${err_msg}: do_in_dir function has internal error"; \
		fi; \
		echo_error "$$err_msg"; \
		exit 1; \
	fi

common/git/submodule/remove: ## Remove submodule
	@##~ SUBMODULE_DIR=PATH - submodule dir path. Should relative without parents (..)
	@##~                      Required.
	@${INCLUDE_GIT_OPS} \
	if ! repo_has_submodules; then \
		exit_with_err "Repo does not contains submodules"; \
	fi; \
	ret_code_is_sub_module="0"; \
	if is_git_dir_submodule_dir "$$SUBMODULE_DIR"; then \
		echo_info "Passed submodule dir '$$SUBMODULE_DIR' for remove"; \
	else \
		ret_code_is_sub_module="$$?"; \
		if [[ "$$ret_code_is_sub_module" == "255" ]]; then \
			exit_with_err "SUBMODULE_DIR '$$SUBMODULE_DIR' incorrect"; \
		fi; \
		exit_with_err "SUBMODULE_DIR '$$SUBMODULE_DIR' is not submodule dir"; \
	fi; \
	echo_info "De-init submodule"; \
	if git submodule deinit -f "$$SUBMODULE_DIR"; then \
		exit_with_err "Cannot submodule deinit"; \
	fi; \
	git_submodule_dir="$${const_git_modules_dir}/$${SUBMODULE_DIR}"; \
	echo_info "Remove submodule from .git '$$git_submodule_dir'"; \
	if ! rm -rfv "$$git_submodule_dir"; then \
		exit_with_err "Cannot remove submodule from .git"; \
	fi; \
	echo_info "Remove submodule dir '$$SUBMODULE_DIR'"; \
	if git rm -rfv "$$SUBMODULE_DIR"; then \
		exit_with_err "Cannot remove submodule dir '$$SUBMODULE_DIR'"; \
	fi
	echo_info "Remove submodule from .gitmodules"; \
	rm_pattern="/\\[submodule "$$SUBMODULE_DIR"\\]/,+2d"
	if ! sed -i "$rm_pattern" .gitmodules; then \
		exit_with_err "Cannot remove module from .gitmodules"; \
	fi; \
	if ! git add .gitmodules "$$SUBMODULE_DIR"; then \
		exit_with_err "Cannot add to git commit .gitmodules and '$$SUBMODULE_DIR'"; \
	fi; \
	if ! git commit --signoff -m "Remove submodule $$SUBMODULE_DIR"; then \
		exit_with_err "Cannot commit .gitmodules and '$$SUBMODULE_DIR'"; \
	fi; \
	echo_info "Submodule '$$SUBMODULE_DIR' removed. .gitmodules content:"; \
	cat .gitmodules || true; \
	echo ""

.PHONY: common/git/check/gitignore common/git/check/has-diff common/git/check/no-changes common/git/submodule/upgrade common/git/submodule/remove