##@ Common. Git

common/git/check/gitignore: ## Check that gitignore file contains another gitignor files rules.
	@##~ ROOT_GITIGNORE=PATH - path to gitignore file for check. Default $(CURDIR)/.gitignore
	@##~ GITIGNORES_WITH_REQUIRED_RULES=PATHS... - comma separated paths to gitignore files that should contains ROOT_GITIGNORE
	@${INCLUDE_SPLIT} \
	root_gitignore="$$ROOT_GITIGNORE"; \
	if [ -z "$$root_gitignore" ]; then \
		root_gitignore="$(CURDIR)/.gitignore"; \
	fi; \
	if [ ! -f "$$root_gitignore" ]; then \
		echo -e "${RED_COLOR}$$root_gitignore not found or not file${NO_COLOR}"; \
		exit 1; \
	fi; \
	if [ -z "$$GITIGNORES_WITH_REQUIRED_RULES" ]; then \
		echo -e "${RED_COLOR}GITIGNORES_WITH_REQUIRED_RULES with comma separated gitignore's to check not passed${NO_COLOR}"; \
		exit 1; \
	fi; \
	echo -e "${GREEN_COLOR}Use root .gitignore as $$root_gitignore${NO_COLOR}"; \
	split_by_comma "gitignores_list" "$$GITIGNORES_WITH_REQUIRED_RULES" "trim_spaces"; \
	if [[ "$${#gitignores_list[@]}" == "0" ]]; then \
		echo -e "${RED_COLOR}GITIGNORES_WITH_REQUIRED_RULES have empty list${NO_COLOR}"; \
		exit 1; \
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
	echo -e "${RED_COLOR}Root gitignore $$root_gitignore not have:${NO_COLOR}"; \
	for err in "$${not_have[@]}"; do \
		echo -e "${RED_COLOR}  $$err${NO_COLOR}"; \
	done; \
	exit 1

common/git/check/has-diff: ## Check diff in repo
	@##~ TARGET_NAME=NAME - if passed run make target before git diff check
	@##~ FILES_TO_CHECK=PATHS... - comma separated paths regexp for check. Can be not passed
	@##~ FILES_TO_SKIP=PATHS... - comma separated paths regexp for skip. Can be not passed
	@${INCLUDE_ECHO} \
	${INCLUDE_SPLIT} \
	set -Eeuo pipefail; \
	target_name="$${TARGET_NAME:-}"; \
	if [ -n "$$target_name" ]; then \
		echo_info "Run '$$target_name'..."; \
		if ! $(MAKE) "$$target_name"; then \
			exit_with_err "$$target_name was failed" 2; \
		fi; \
	fi; \
	files_check="$${FILES_TO_CHECK:-}"; \
	if [ -n "$$files_check" ]; then \
		split_by_comma "patterns_for_check" "$$files_check" "trim_spaces"; \
	fi; \
	patterns_for_skip=(); \
	files_skip="$${FILES_TO_SKIP:-}"; \
	if [ -n "$$files_skip" ]; then \
		split_by_comma "patterns_for_skip" "$$files_skip" "trim_spaces"; \
	fi; \
	output="$$(git diff --name-status | cut -f 2 | sort)"; \
	if [ -z "$$output" ]; then \
		exit 0; \
	fi; \
	files=(); \
	while IFS= read -r fl; do \
    	files+=("$$fl"); \
	done <<<"$$output"; \
	changed=(); \
	for fl_a in "$${files[@]}"; do \
		skipped=""; \
		for skp in "$${patterns_for_skip[@]}"; do \
			if grep -qE "$$skp" <<<"$$fl_a"; then \
				skipped="true"; \
				break; \
			fi; \
		done; \
		if [ -n "$$skipped" ]; then \
			echo_info "$$fl_a skipped"; \
			continue; \
		fi; \
    	if [ "$${#patterns_for_check[@]}" -eq 0 ]; then \
			changed+=("$$fl_a"); \
			continue; \
		fi; \
		file_changed=""; \
		for chn in "$${patterns_for_check[@]}"; do \
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
	if [ "$${#changed[@]}" -eq 0 ]; then \
		exit 0; \
	fi; \
	echo_err "Files changed:"; \
	for chn_f in "$${changed[@]}"; do \
		echo_err "  $$chn_f"; \
	done; \
	exit 1


.PHONY: common/git/check/gitignore common/git/check/has-diff