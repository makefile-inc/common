MAKEFLAGS += --no-print-directory

SHELL = /usr/bin/env bash

.DEFAULT_GOAL := help

ifndef SET_BINARIES_PATH
  SET_BINARIES_PATH = $(CURDIR)/bin
endif

BINARIES_PATH = $(abspath $(SET_BINARIES_PATH))

export PATH := $(BINARIES_PATH):$(PATH)

RED_COLOR    := \033[0;31m
GREEN_COLOR  := \033[0;32m
YELLOW_COLOR := \033[0;33m
CYAN_COLOR   := \033[36m
BOLD_COLOR   := \033[1m
NO_COLOR     := \033[0m

ARCH_NAME := $(shell uname -m)

AWK_BIN := awk

OS_LINUX := linux
OS_MACOS := darwin
AVAILABLE_OSES := $(OS_LINUX) $(OS_MACOS)

ARCH_AMD := amd64
ARCH_ARM := arm64
AVAILABLE_ARCHS = $(ARCH_AMD) $(ARCH_ARM)

OS_NAME := $(shell uname)
ifndef OS_CALCULATED
	ifeq ($(OS_NAME), Linux)
		OS_CALCULATED = $(OS_LINUX)
	else ifeq ($(OS_NAME), Darwin)
		OS_CALCULATED = $(OS_MACOS)
		AWK_BIN = gawk
		ifeq (, $(shell which gawk 2> /dev/null))
        	$(error "gawk not found")
    	endif
	else
		$(error Incorrect os)
	endif
endif

ifndef ARCH_CALCULATED
	ifeq ($(ARCH_NAME), x86_64)
		ARCH_CALCULATED = $(ARCH_AMD)
	else ifeq ($(ARCH_NAME), arm64)
		ARCH_CALCULATED = $(ARCH_ARM)
	else
		$(error Incorrect arch)
	endif
endif

# RUN_WITH_CLEANUP - run target and call another tharget after run first (with or withouth error)
# Uses with $(call ...)
# $1 - target to run
# $2 - cleanup target
# Example:
#   include *.mk
#   test/sleep-exec-ok:
#	    @sleep 2; \
#	    echo "Do ok"; \
#	    exit 0
#   test/sleep-exec-fail:
#	    @sleep 2; \
#	    echo "Do fail"; \
#	    exit 3
#   test/cleanup/run:
#	    @echo "Do cleanup"
#   test/run-with-cleanup/ok:
#	    @$(call RUN_WITH_CLEANUP,test/sleep-exec-ok,test/cleanup/run)
#   test/run-with-cleanup/fail:
#       @$(call RUN_WITH_CLEANUP,test/sleep-exec-fail,test/cleanup/run)
define RUN_WITH_CLEANUP
$(MAKE) $(1) && $(MAKE) $(2) || (ret=$$?; $(MAKE) $(2) && exit $$ret)
endef

# INCLUDE_ECHO - add next sh functions:
#   echo_err - print to stderr first argument with red color
#   echo_info - print to stderr first argument with green color
#   echo_warn - print to stderr first argument with yellow color
#   exit_with_err - print to stderr first argument with red color and exit with non-zero exit code (default 1, maybe passed  with second arg)
# Example include:
#   @${INCLUDE_ECHO} \ - slash is required!
# Example:
#   include *.mk
#   test/echo:
#	    @${INCLUDE_ECHO} \
#	    echo_info "Done"; \
#	    echo_warn "Warn"; \
#	    echo_err "Error!";
#   test/error_exit_default:
#	    @${INCLUDE_ECHO} \
#	    exit_with_err "Fail!"
#   test/error_exit:
#	    @${INCLUDE_ECHO} \
#	    exit_with_err "Fail!" 3
# Can be included multiple times because sh redeclare function without error
define INCLUDE_ECHO
function echo_err() { \
	echo -e "${RED_COLOR}$${1:-}${NO_COLOR}" >&2; \
}; \
function echo_info() { \
	echo -e "${GREEN_COLOR}$${1:-}${NO_COLOR}" >&2; \
}; \
function echo_warn() { \
	echo -e "${YELLOW_COLOR}$${1:-}${NO_COLOR}" >&2; \
}; \
function exit_with_err() { \
	exit_code="${2:-}"; \
	if [ -z "$$exit_code" ]; then \
		exit_code="1"; \
	fi; \
	if [ "$$exit_code" -eq 0 ]; then \
		exit_code="1"; \
	fi; \
	echo_err "$${1:-Error}"; \
	exit "$$exit_code"; \
};
endef

# INCLUDE_SPLIT - add next sh functions:
#   trim_spaces_left - trim whitespaces from left
#     Arguments:
#       $1 - string to trim
#   trim_spaces_right - trim whitespaces from right
#     Arguments:
#       $1 - string to trim
#   trim_spaces - trim whitespaces from right and left
#     Arguments:
#       $1 - string to trim
#   split_by - split string by separator to global array
#     Arguments:
#       $1 - separator (can be multi-character)
#       $2 - name of destination array variable
#       $3 - string to split
#   split_by_comma - split string by comma-separator to global array
#     Arguments:
#       $1 - name of destination array variable
#       $2 - string to split
#   split_by_space - split string by space-separator to global array
#     Arguments:
#       $1 - name of destination array variable
#       $2 - string to split
#   split_by_new_line - split string by new-line-separator to global array
#     Arguments:
#       $1 - name of destination array variable
#       $2 - string to split
# Example include:
#   @${INCLUDE_ECHO} \ - slash is required!
# Example:
#   include *.mk
#   test/trim:
# 	    @${INCLUDE_SPLIT} \
# 	    b="$$(trim_spaces $$'\n  \t\n\t   from begin')"; \
# 	    e="$$(trim_spaces $$'from end\n  \t\n\t  ')"; \
# 	    m="$$(trim_spaces $$'\n  \t\n\tin middle\n  \t\n\t  ')"; \
# 	    n="$$(trim_spaces "no trim")"; \
# 	    echo "'$$b'";\
# 	    echo "'$$e'";\
# 	    echo "'$$m'";\
# 	    echo "'$$n'"
# 	test/split:
# 		@${INCLUDE_SPLIT} \
# 		function print_arr() { \
# 			local function_array=("$$@"); \
# 			for item in "$${function_array[@]}"; do \
# 				echo "Value: '$$item'"; \
# 			done; \
# 		}; \
# 		comma="a,b c,d"; \
# 		split_by_comma "comma_arr" "$$comma"; \
# 		echo "Comma-separated:"; \
# 		print_arr "$${comma_arr[@]}"; \
# 		new_line=$$'Hello with\n Name'; \
# 		split_by_new_line "new_line_arr" "$$new_line"; \
# 		echo "New line-separated:"; \
# 		print_arr "$${new_line_arr[@]}"; \
# 		spaces=$$'val ba bbval\nccc'; \
# 		split_by_space "spaces_arr" "$$spaces"; \
# 		echo "Spaces-separated:"; \
# 		print_arr "$${spaces_arr[@]}"; \
# 		own=$$'val ba. bbval\nccc'; \
# 		split_by '.' "own_arr" "$$own"; \
# 		echo "Dot-separated:"; \
# 		print_arr "$${own_arr[@]}"; \
# 		multi=$$'val ba\n b|||bval|||ccc'; \
# 		split_by '|||' "multi_arr" "$$multi"; \
# 		echo "Multi-separated:"; \
# 		print_arr "$${multi_arr[@]}"
# Can be included multiple times because sh redeclare function without error
define INCLUDE_SPLIT
function trim_spaces_left() { \
    local trimmed="$${1:-}"; \
    echo -n "$${trimmed#"$${trimmed%%[![:space:]]*}"}"; \
}; \
function trim_spaces_right() { \
    local trimmed="$${1:-}"; \
    echo -n "$${trimmed%"$${trimmed##*[![:space:]]}"}"; \
}; \
function trim_spaces() { \
    local trimmed="$${1:-}"; \
    trimmed="$$(trim_spaces_left "$$trimmed")"; \
    trimmed="$$(trim_spaces_right "$$trimmed")"; \
    echo -n "$$trimmed"; \
}; \
function split_by() { \
	local _sep="$${1:-}"; \
	if [ -z "$$_sep" ]; then \
		echo -e "${RED_COLOR}Separator for split_by not passed as first arg ${NO_COLOR}" >&2; \
		exit 1; \
	fi; \
	_sep="$$(printf '%s\n' "$$_sep" | sed 's/[]\/$$*.^[]/\\&/g' | sed ':a;N;$$!ba;s/\n/\\n/g')"; \
	local _dest="$${2:-}"; \
	if [ -z "$$_dest" ]; then \
		echo -e "${RED_COLOR}Destination array for split_by not passed as second arg ${NO_COLOR}" >&2; \
		exit 1; \
	fi; \
	local _str="$${3:-}"; \
	readarray -t -d '' "$$_dest" < <(sed -z "s/$$_sep/\x00/g" < <(printf '%s' "$$_str")); \
}; \
function split_by_comma() { \
	local _dest="$${1:-}"; \
	local _str="$${2:-}"; \
	split_by ',' "$$_dest" "$$_str"; \
}; \
function split_by_space() { \
	local _dest="$${1:-}"; \
	local _str="$${2:-}"; \
	split_by ' ' "$$_dest" "$$_str"; \
}; \
function split_by_new_line() { \
	local _dest="$${1:-}"; \
	local _str="$${2:-}"; \
	split_by $$'\n' "$$_dest" "$$_str"; \
};
endef

help:
	@echo -e "Usage: make ${YELLOW_COLOR}<target>${NO_COLOR} ${CYAN_COLOR}OPTION${NO_COLOR}=<value>"; \
	printf "  ${YELLOW_COLOR}%-42s${NO_COLOR}  %s\n" "help" "Show this message"; \
	for inc in $(MAKEFILE_LIST); do \
		$(AWK_BIN) 'BEGIN { \
	    		FS = ":.*##"; \
	  		} \
	  		/^[a-zA-Z0-9_-/]+:.*?##/ { printf "  ${YELLOW_COLOR}%-42s${NO_COLOR} %s\n", $$1, $$2 } \
	  		/^.?.?##~/               { printf "     %-42s${CYAN_COLOR}%-42s${NO_COLOR}\n", "", substr($$1, 6) } \
	  		/^##@/                   { printf "\n${BOLD_COLOR}%s${NO_COLOR}\n", substr($$0, 5) } ' \
		"$$inc"; \
	done

.PHONY: help