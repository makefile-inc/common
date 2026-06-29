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
	echo -e "${RED_COLOR}$$1${NO_COLOR}" >&2; \
}; \
function echo_info() { \
	echo -e "${GREEN_COLOR}$$1${NO_COLOR}" >&2; \
}; \
function echo_warn() { \
	echo -e "${YELLOW_COLOR}$$1${NO_COLOR}" >&2; \
}; \
function exit_with_err() { \
	exit_code="$2"; \
	if [ -z "$$exit_code" ]; then \
		exit_code="1"; \
	fi; \
	if [ "$$exit_code" -eq 0 ]; then \
		exit_code="1"; \
	fi; \
	echo_err "$$1"; \
	exit "$$exit_code"; \
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