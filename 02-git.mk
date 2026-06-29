##@ Common. Git

check/common/gitignore: ## Check that gitignore file contains another gitignor files rules.
	@##~ ROOT_GITIGNORE=PATH - path to gitignore file for check. Default $(CURDIR)/.gitignore
	@##~ GITIGNORES_WITH_REQUIRED_RULES=PATHS... - comma separated paths to gitignore files that should contains ROOT_GITIGNORE
	@root_gitignore="$$ROOT_GITIGNORE"; \
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
	IFS=',' read -r -a gitignores_list <<< "$$GITIGNORES_WITH_REQUIRED_RULES"; \
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
