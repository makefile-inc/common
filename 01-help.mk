# Copyright 2026
# license that can be found in the LICENSE file.

__CUR_MAKEFILE_PATH := $(firstword $(MAKEFILE_LIST))

# INCLUDE_MAKE_HELP - add next sh functions:
#   out_help_for_file - print help for Makefile file
#     Arguments:
#       $1 - Makefile file path
#   
#   Add next variables:
#     CURRENT_MAKEFILE_PATH - current run Makefile (not absolute)
#     CURRENT_MAKEFILE_PATH_FULL - current run Makefile (absolute path)
# Example include:
#   @${INCLUDE_MAKE_HELP} \ - slash is required!
# Example:
#   include *.mk
#   test/help:
#	    @${INCLUDE_MAKE_HELP} \
#	    out_help_for_file "/home/user/project/00-out-include.mk"
# Can be included multiple times because sh redeclare function without error
define INCLUDE_MAKE_HELP
CURRENT_MAKEFILE_PATH="$(__CUR_MAKEFILE_PATH)"; \
CURRENT_MAKEFILE_PATH_FULL="$$CURRENT_MAKEFILE_PATH_FULL"; \
if ! CURRENT_MAKEFILE_PATH_FULL="$$(realpath "$$CURRENT_MAKEFILE_PATH")"; then \
	CURRENT_MAKEFILE_PATH_FULL="$$CURRENT_MAKEFILE_PATH"; \
fi; \
function out_help_for_file() { \
	local ff="$${1:-}"; \
	if [ -z "$$ff" ]; then \
		return 0; \
	fi; \
	if [ ! -f "$$ff" ]; then \
		return 0; \
	fi; \
	$(AWK_BIN) 'BEGIN { \
			FS = ":.*##"; \
		} \
		/^[a-zA-Z0-9_-/]+:.*?##/ { printf "  ${YELLOW_COLOR}%-42s${NO_COLOR} %s\n", $$1, $$2 } \
		/^.?.?##~/               { printf "     %-42s${CYAN_COLOR}%-42s${NO_COLOR}\n", "", substr($$1, 6) } \
		/^##@/                   { printf "\n${BOLD_COLOR}%s${NO_COLOR}\n", substr($$0, 5) } ' \
	"$$ff"; \
};
endef

help:
	@${INCLUDE_ECHO} \
	${INCLUDE_MAKE_HELP} \
	${INCLUDE_SPLIT} \
	echo -e "Usage: make ${YELLOW_COLOR}<target>${NO_COLOR} ${CYAN_COLOR}OPTION${NO_COLOR}=<value>"; \
	echo ""; \
	printf "${BOLD_COLOR}%s${NO_COLOR}\n" "Common. Makefile help"; \
	printf "  ${YELLOW_COLOR}%-42s${NO_COLOR}  %s\n" "help" "Show this message"; \
	printf "  %-44s  ${CYAN_COLOR}%-42s${NO_COLOR}\n" "" "HELP_DISABLE_LIBRARIES=true - if passed output target only from running Makefile"; \
	printf "  %-44s  ${CYAN_COLOR}%-42s${NO_COLOR}\n" "" "                            - If passed ignore another options."; \
	printf "  %-44s  ${CYAN_COLOR}%-42s${NO_COLOR}\n" "" "HELP_LIBRARIES_FIRST=true   - if passed output targets from running Makefile last,"; \
	printf "  %-44s  ${CYAN_COLOR}%-42s${NO_COLOR}\n" "" "                            - libraries first"; \
	printf "  %-44s  ${CYAN_COLOR}%-42s${NO_COLOR}\n" "" "HELP_LIBRARIES_OUT=PATHS..  - Comma separated full paths libraries for output"; \
	printf "  %-44s  ${CYAN_COLOR}%-42s${NO_COLOR}\n" "" "                            - Optional. Can be set with HELP_LIBRARIES_FIRST"; \
	if [ -n "$$HELP_DISABLE_LIBRARIES" ]; then \
		out_help_for_file "$$CURRENT_MAKEFILE_PATH_FULL"; \
		exit 0; \
	fi; \
	libs_for_out=();\
	if [ -n "$$HELP_LIBRARIES_OUT" ]; then \
		libs_split=();\
		split_by_comma "libs_split" "$$HELP_LIBRARIES_OUT" "trim_spaces"; \
		for lib_dir in "$${libs_split[@]}"; do \
			if [ -z "$$lib_dir" ]; then \
				continue; \
			fi; \
			if [ ! -d "$$lib_dir" ]; then \
				exit_with_err "Lib dir '$$lib_dir' is not dir"; \
			fi; \
			lib_dir_real=""; \
			if ! lib_dir_real="$$(realpath "$$lib_dir")"; then \
				exit_with_err "Cannot get real path for '$$lib_dir'"; \
			fi; \
			libs_for_out+=("$$lib_dir_real"); \
		done; \
	fi; \
	out_after=(); \
	for inc in $(MAKEFILE_LIST); do \
		inc_real=""; \
		if ! inc_real="$$(realpath "$$inc")"; then \
			exit_with_err "Cannot get real path for makefile '$$inc'"; \
		fi; \
		if [ -d "$$inc_real" ]; then \
			continue; \
		fi; \
		inc_dir=""; \
		if ! inc_dir="$$(dirname "$$inc_real")"; then \
			exit_with_err "Cannot get dir for makefile '$$inc_real'"; \
		fi; \
		if [[ "$$HELP_LIBRARIES_FIRST" != "" && "$$inc_real" == "$$CURRENT_MAKEFILE_PATH_FULL" ]]; then \
			out_after+=("$$CURRENT_MAKEFILE_PATH_FULL"); \
			continue; \
		fi; \
		if [[ "$${#libs_for_out[@]}" != "0" ]]; then \
			if [[ "$$HELP_LIBRARIES_FIRST" == "" && "$$inc_real" == "$$CURRENT_MAKEFILE_PATH_FULL" ]]; then \
				out_help_for_file "$$CURRENT_MAKEFILE_PATH_FULL"; \
			else \
				for out_lib in "$${libs_for_out[@]}"; do \
					if [[ "$$out_lib" == "$$inc_dir" ]]; then \
						out_help_for_file "$$inc_real"; \
						break; \
					fi; \
				done; \
			fi; \
		else \
			out_help_for_file "$$inc_real"; \
		fi; \
	done; \
	for after_inc in "$${out_after[@]}"; do \
		out_help_for_file "$$after_inc"; \
	done

.PHONY: help