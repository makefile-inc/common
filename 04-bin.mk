# Copyright 2026
# license that can be found in the LICENSE file.

# INCLUDE_CHECK_BINARY - add next sh function:
#   check_binary - check that binary is exists in BINARIES_PATH and executable and have correct version
#     Arguments:
#       $1 - binary name without path
#       $2 - version argument for binary for extract version
#       $3 - version to check. Function uses grep for match version
#   if binary present and executable and have correct version returns zero code, otherwise - 1, invalid args - 2
#
#   check_and_download_bin - check that binary is exists in BINARIES_PATH and executable and have correct version
#     if not - download.
#     Arguments:
#       $1 - url to download (can be passed with env INSTALL_BIN_URL). Can be contains next string for substitution 
#          @BIN_VER@  - replace to version passed via $3
#          @BIN_OS@   - replace to calculated os name $(OS_CALCULATED) (linux or darwin) 
#          @BIN_ARCH@ - replace to calculated os name $(ARCH_CALCULATED) (amd64 or arm64) 
#       $2 - binary name without path (can be passed with env INSTALL_BIN_NAME)
#       $3 - version argument passed in binary for extract version (can be passed with env INSTALL_BIN_VERSION_ARG)
#       $4 - version to check. Function uses grep for match version (can be passed with env INSTALL_BIN_VERSION)
#   if binary present and executable and have correct version returns zero code, otherwise - 1, invalid args - 2
#
#   check_and_get_bin - check that binary is exists in `BINARIES_PATH` and executable and have correct version
#     if not - call passed function for get binary.
#     Arguments:
#       $1 - function name for get binary. Function pass next args to get function
#          $1 - version of binary
#          $2 - arch (amd64 or arm64)
#          $3 - os (linux or darwin) 
#          $4 - binary name only 
#          $5 - full binary path
#          $6 - binaries path $(BINARIES_PATH) 
#       $2 - binary name without path (can be passed with env INSTALL_BIN_NAME)
#       $3 - version argument passed in binary for extract version (can be passed with env INSTALL_BIN_VERSION_ARG)
#       $4 - version to check. Function uses grep for match version (can be passed with env INSTALL_BIN_VERSION)
#     if binary present and executable and have correct version returns zero code, otherwise - 1, invalid args - 2
# Example include:
#   @${INCLUDE_CHECK_BINARY} \ - slash is required!
# Example:
#   include *.mk
#   ifeq ($(OS_CALCULATED), $(OS_LINUX))
# 		JQ_PLATFORM = OS_LINUX
#   else ifeq ($(OS_CALCULATED), $(OS_MACOS))
#		JQ_PLATFORM = macos
#   endif
#   JQ_PLATFORM_ARCH = $(JQ_PLATFORM)-$(ARCH_CALCULATED)
#   bin/jq/check:
# 		@${INCLUDE_CHECK_BINARY} \
#  		if ! check_binary jq "--version" "1.8.1"; then \
# 			echo "Download..."; \
# 		fi
#   bin/jq:
# 		@${INCLUDE_CHECK_BINARY} \
#  		url="https://github.com/jqlang/jq/releases/download/jq-@BIN_VER@/jq-$(JQ_PLATFORM_ARCH)"
# 		if ! check_and_download_bin jq "--version" "1.8.1" "$$url"; then \
# 			echo "Download..."; \
# 		fi
#   _test/install/dummy: export INSTALL_BIN_NAME = $(DUMMY_BIN)
#   _test/install/dummy: export INSTALL_BIN_VERSION_ARG = ver
#   _test/install/dummy: export INSTALL_BIN_VERSION = 0.0.1
#   _test/install/dummy:
# 		@function get_dummy() { \
# 			local ver="$$1"; \
# 			local arch="$$2"; \
# 			local os="$$3"; \
# 			local name="$$4"; \
# 			local dest="$$5"; \
# 			local pt="$$6"; \
# 			{ \
# 				echo -n "#"; \
# 				echo '!/usr/bin/env bash'; \
#  				echo 'if [[ $$1 == "ver" ]]; then'; \
#  				echo -n '  echo "'; \
#  				echo -n "name=$$name; path=$$pt; arch=$$arch; os=$$os; v$$ver"; \
# 				echo '"'; \
# 				echo 'fi'; \
# 			} > "$$dest"; \
# 		}; \
# 		${INCLUDE_CHECK_BINARY} \
# 		if ! check_and_get_bin get_dummy; then \
# 			exit 1; \
# 		fi; \
# 		if [ ! -x "$(DUMMY_FULL_BIN)" ]; then \
# 			exit_with_err "$(DUMMY_FULL_BIN) is not executable"; \
# 		fi
#   bin/yq:
# 		@${INCLUDE_CHECK_BINARY} \
# 		url="https://github.com/mikefarah/yq/releases/download/v@BIN_VER@/yq_@BIN_OS@_@BIN_ARCH@"; \
# 		if ! check_and_download_bin jq "--version" "4.0.0" "$$url"; then \
# 			exit 1; \
# 		fi
# Can be included multiple times because sh redeclare function without error
define INCLUDE_CHECK_BINARY
${INCLUDE_ECHO} \
function check_binary() { \
	local binary="$${1:-}"; \
	local version_arg="$${2:-}"; \
	local version="$${3:-}"; \
	if [ -z "$$binary" ]; then \
  		echo_err "binary not passed as first arg"; \
  		return 2; \
	fi; \
	if [ -z "$$version_arg" ]; then \
  		echo_err "binary version argument not passed as second arg"; \
 		return 2; \
	fi; \
	if [ -z "$$version" ]; then \
  		echo_err "target binary version not passed as third arg"; \
  		return 2; \
	fi; \
	binary_full_path="$(BINARIES_PATH)/$${binary}"; \
	if [ ! -x "$$binary_full_path" ]; then \
  		echo_warn "$$binary_full_path not exists or not executable"; \
  		return 1; \
	fi; \
	if ! got_bin_ver="$$("$$binary_full_path" "$$version_arg")"; then \
  		echo_err "${RED_COLOR}Version of $$binary_full_path cannot extracted!${NO_COLOR}"; \
  		return 2; \
	fi; \
	if ! grep -q "$$version" <<<"$$got_bin_ver"; then \
  		echo_warn "Version of $$binary_full_path not match $$version Version is $$got_bin_ver"; \
  		return 1; \
	fi; \
	echo_info "$$binary_full_path with $$version already installed"; \
	return 0; \
}; \
function check_and_download_bin() { \
	local passed_url="$${INSTALL_BIN_URL:-}"; \
	if [ -z "$$passed_url" ]; then \
		passed_url="$${1:-}"; \
		if [ -z "$$passed_url" ]; then \
			echo_err "Url for download binary is not passed"; \
			return 2; \
		fi; \
	fi; \
	local binary="$${INSTALL_BIN_NAME:-}"; \
	if [ -z "$$binary" ]; then \
		binary="$${2:-}"; \
	fi; \
	local version_arg="$${INSTALL_BIN_VERSION_ARG:-}"; \
	if [ -z "$$version_arg" ]; then \
		version_arg="$${3:-}"; \
	fi; \
	local version="$${INSTALL_BIN_VERSION:-}"; \
	if [ -z "$$version" ]; then \
		version="$${4:-}"; \
	fi; \
	local ret_code="2"; \
	if ! check_binary "$$binary" "$$version_arg" "$$version"; then \
		ret_code="$$?"; \
		if [ "$$ret_code" -eq 2 ]; then \
			echo_err "Incorrect args for check_and_download_bin"; \
			return 2; \
		fi; \
		local url="$$passed_url"; \
		local sub_ver="gsub(\"@BIN_VER@\", \"$$version\")"; \
		url="$$(echo "$$url" | ${AWK_BIN} "$$sub_ver")"; \
		if [ -z "$$url" ]; then \
			url="$$passed_url"; \
		fi; \
		passed_url="$$url"; \
		local sub_arch="gsub(\"@BIN_ARCH@\", \"$(ARCH_CALCULATED)\")"; \
		url="$$(echo "$$url" | ${AWK_BIN} "$$sub_arch")"; \
		if [ -z "$$url" ]; then \
			url="$$passed_url"; \
		fi; \
		passed_url="$$url"; \
		local sub_os="gsub(\"@BIN_OS@\", \"$(OS_CALCULATED)\")"; \
		url="$$(echo "$$url" | ${AWK_BIN} "$$sub_os")"; \
		if [ -z "$$url" ]; then \
			url="$$passed_url"; \
		fi; \
		local dest="$(BINARIES_PATH)/$${binary}"; \
		echo_info "Install $${binary} to $$dest via url $$url"; \
		if ! curl -sSfLo "$$dest" "$$url"; then \
			echo_err "Cannot download $$binary"; \
			return 1; \
		fi; \
		if ! chmod +x "$$dest"; then \
			echo_err "Cannot chmod $$dest"; \
			return 1; \
		fi; \
		return 0; \
	fi; \
	return 0; \
}; \
function check_and_get_bin() { \
	local get_func="$$1"; \
	if [ -z "$$get_func" ]; then \
		echo_err "get binary function not passed as first arg"; \
		return 2; \
	fi; \
	local binary="$${INSTALL_BIN_NAME:-}"; \
	if [ -z "$$binary" ]; then \
		binary="$${2:-}"; \
	fi; \
	local version_arg="$${INSTALL_BIN_VERSION_ARG:-}"; \
	if [ -z "$$version_arg" ]; then \
		version_arg="$${3:-}"; \
	fi; \
	local version="$${INSTALL_BIN_VERSION:-}"; \
	if [ -z "$$version" ]; then \
		version="$${4:-}"; \
	fi; \
	local ret_code="2"; \
	if ! check_binary "$$binary" "$$version_arg" "$$version"; then \
		ret_code="$$?"; \
		if [ "$$ret_code" -eq 2 ]; then \
			echo_err "Incorrect args for check_and_download_bin"; \
			return 2; \
		fi; \
		local dest="$(BINARIES_PATH)/$${binary}"; \
		echo_info "Install $${binary} to $$dest via call func:"; \
		echo_info "  $$get_func \"$$version\" \"$(ARCH_CALCULATED)\" \"$(OS_CALCULATED)\" \"$$binary\" \"$$dest\" \"$(BINARIES_PATH)\""; \
		if ! "$$get_func" "$$version" "$(ARCH_CALCULATED)" "$(OS_CALCULATED)" "$$binary" "$$dest" "$(BINARIES_PATH)"; then \
			echo_err "get binary function returned error"; \
			return 1; \
		fi; \
		if ! chmod +x "$$dest"; then \
			echo_err "Cannot chmod $$dest"; \
			return 1; \
		fi; \
		return 0; \
	fi; \
	return 0; \
};
endef

# INCLUDE_BIN_DYNAMIC - add next sh function:
#   check_dynamic_executable - check that binary is dynamic linked or not
#     Arguments:
#       $1 - binary path. Required. Also can be passed via env TARGET_BIN_TO_CHECK
#       $2 - if not empty check that executable is dynamic-linked, otherwise that static linked
#            Also can be passed via env TARGET_BIN_SHOULD_DYNAMIC
#	         Optional.
#   if have argument errors - returns 2, returns 1 if executable not/is dynamic-linked depended on $2
#   If executable linked correct returns 0
# Example include:
#   @${INCLUDE_BIN_DYNAMIC} \ - slash is required!
# Example:
#   include *.mk
#
#   check/dynamic: export TARGET_BIN_TO_CHECK = $(BUILD_PATH)/app-dynamic
#   check/dynamic: export TARGET_BIN_SHOULD_DYNAMIC = true
#   check/dynamic:
# 		@${INCLUDE_BIN_DYNAMIC} \
# 		if ! check_dynamic_executable; then \
# 			exit 1; \
# 		fi
#
#   check/static: export TARGET_BIN_TO_CHECK = $(BUILD_PATH)/app-static
#   check/static:
# 		@${INCLUDE_BIN_DYNAMIC} \
# 		if ! check_dynamic_executable; then \
# 			exit 1; \
# 		fi
# Can be included multiple times because sh redeclare function without error
define INCLUDE_BIN_DYNAMIC
${INCLUDE_ECHO} \
function check_dynamic_executable() { \
	local bin_path="$${1:-}"; \
	if [ -z "$$bin_path" ]; then \
		bin_path="$${TARGET_BIN_TO_CHECK:-}"; \
  		if [ -z "$$bin_path" ]; then \
  			echo_err "$$bin_path not passed as first arg or via TARGET_BIN_TO_CHECK env"; \
			return 2; \
		fi; \
	fi; \
	local should_dynamic="$${2:-}"; \
	if [ -z "$$should_dynamic" ]; then \
		should_dynamic="$${TARGET_BIN_SHOULD_DYNAMIC:-}"; \
	fi; \
	local full_path=""; \
	if ! full_path="$$(realpath "$$bin_path")"; then \
		echo_err "cannot get full path for $$bin_path"; \
		return 2; \
	fi; \
	if [ ! -x "$$full_path" ]; then \
  		echo_err "$$full_path is not executable"; \
		return 2; \
	fi; \
	if [ -n "$$should_dynamic" ]; then \
  		if ! ldd "$$full_path"; then \
			echo_err "$$full_path is not dynamic linked but should"; \
			return 1; \
		fi; \
		return 0; \
	fi; \
	if ldd "$$full_path"; then \
		echo_err "$$full_path is dynamic linked but should not"; \
		return 1; \
	fi; \
	return 0; \
};
endef

# CHECK_BINARY - check that binary is exists in BINARIES_PATH and executable and have correct version
#     Arguments:
#       $(1) - binary name without path
#       $(2) - version argument for binary for extract version
#       $(3) - version to check. Function uses grep for match version
#   if binary present and executable and have correct version returns zero code, otherwise non zero
# Example:
#   include *.mk
#   ifeq ($(OS_CALCULATED), $(OS_LINUX))
# 		JQ_PLATFORM = OS_LINUX
#   else ifeq ($(OS_CALCULATED), $(OS_MACOS))
#		JQ_PLATFORM = macos
#   endif
#   JQ_PLATFORM_ARCH = $(JQ_PLATFORM)-$(ARCH_CALCULATED)
#   bin/jq:
#  		$(shell $(call CHECK_BINARY,$(JQ_BIN_NAME),--version,$(JQ_VERSION)))
# 		@if [ "$(.SHELLSTATUS)" -ne 0 ]; then \
# 			set -Eeuo pipefail; \
# 			dest="$(JQ_BIN_FULL)"; \
# 			echo -e "${GREEN_COLOR}Install yq for go to $$dest${NO_COLOR}"; \
# 			curl -sSfLo "$$dest" https://github.com/jqlang/jq/releases/download/jq-$(JQ_VERSION)/jq-$(JQ_PLATFORM_ARCH); \
# 			chmod +x "$$dest"; \
# 		fi
define CHECK_BINARY
${INCLUDE_CHECK_BINARY} \
if ! check_binary "$(1)" "$(2)" "$(3)"; then \
  exit 1; \
fi; \
exit 0;
endef

YQ_BIN_NAME  = yq
YQ_BIN_FULL  = $(BINARIES_PATH)/$(YQ_BIN_NAME)

JQ_BIN_NAME = jq
JQ_BIN_FULL = $(BINARIES_PATH)/$(JQ_BIN_NAME)

TAR_BIN = tar
FIND_BIN = find

ifeq ($(OS_CALCULATED), $(OS_LINUX))
	JQ_PLATFORM = $(OS_LINUX)
else ifeq ($(OS_CALCULATED), $(OS_MACOS))
	JQ_PLATFORM = macos
	TAR_BIN = gtar
	FIND_BIN = gfind
endif

JQ_PLATFORM_ARCH = $(JQ_PLATFORM)-$(ARCH_CALCULATED)

##@ Common. Directories

bin: ## Make bin directory
	@##~ SET_BINARIES_PATH=PATH - dir utils binaries. By default $(CURDIR)/.bin
	@mkdir -p "$(BINARIES_PATH)"

##@ Common. Checks binary is installed in system

check/installed/bin: ## Check binary is installed. use $(MAKE) check/installed/bin for call!
	@##~ BIN_NAME=NAME - name of binary for check
	@if [ -z "$$BIN_NAME" ]; then \
		echo "${RED_COLOR}BIN_NAME not passed${NO_COLOR}"; \
        exit 1; \
	fi; \
	if ! command -v "$$BIN_NAME" > /dev/null; then \
        echo "${RED_COLOR}$$BIN_NAME not installed${NO_COLOR}"; \
        exit 1; \
    fi

check/installed/curl: export BIN_NAME = curl
check/installed/curl: ## curl
	@$(MAKE) check/installed/bin

check/installed/docker: export BIN_NAME = docker
check/installed/docker: ## docker
	@$(MAKE) check/installed/bin

check/installed/tar: export BIN_NAME = $(TAR_BIN)
check/installed/tar: ## GNU tar
	@$(MAKE) check/installed/bin

check/installed/find: export BIN_NAME = $(FIND_BIN)
check/installed/find: ## GNU find
	@$(MAKE) check/installed/bin

check/installed/sha256sum: export BIN_NAME = sha256sum
check/installed/sha256sum: ## sha256sum
	@$(MAKE) check/installed/bin

##@ Common. Check executables

check/bin/linked/dynamic: export TARGET_BIN_SHOULD_DYNAMIC = true
check/bin/linked/dynamic: ## Check that executable is dynamic-linked
	@##~ TARGET_BIN_TO_CHECK=PATH - path to executable to check
	@${INCLUDE_BIN_DYNAMIC} \
	if ! check_dynamic_executable; then \
		exit 1; \
	fi

check/bin/linked/static: ## Check that executable is static-linked
	@##~ TARGET_BIN_TO_CHECK=PATH - path to executable to check
	@${INCLUDE_BIN_DYNAMIC} \
	if ! check_dynamic_executable; then \
		exit 1; \
	fi

##@ Common. Install binary to local bin dir

install/binary: bin check/installed/curl ## install (download) binary with provided version to BINARIES_PATH (./bin dir by default) use $(MAKE) install/binary for call!
	@##~ INSTALL_BIN_NAME=NAME - name of binary in BINARIES_PATH
	@##~ INSTALL_BIN_VERSION=VERSION - version of binary
	@##~ INSTALL_BIN_VERSION_ARG=ARG - version argument passed in binary for extract version, by default --version
	@##~ INSTALL_BIN_URL=URL - url for download binary. Can contains: 
	@##~   @BIN_VER@ - replace to version passed via INSTALL_BIN_VERSION 
	@##~   @BIN_OS@ - replace to calculated os name $(OS_CALCULATED) (linux or darwin)
	@##~   @BIN_ARCH@ - replace to calculated os name $(ARCH_CALCULATED) (amd64 or arm64)
	@##~     For example:
	@##~       https://github.com/mikefarah/yq/releases/download/v@BIN_VER@/yq_@BIN_OS@_@BIN_ARCH@
	@${INCLUDE_CHECK_BINARY} \
	if [ -z "$$INSTALL_BIN_NAME" ]; then \
		echo_err "INSTALL_BIN_NAME not passed"; \
		exit 2; \
	fi; \
	if [ -z "$$INSTALL_BIN_VERSION" ]; then \
		echo_err "INSTALL_BIN_VERSION not passed"; \
		exit 2; \
	fi; \
	if [ -z "$$INSTALL_BIN_URL" ]; then \
		echo_err "INSTALL_BIN_URL not passed"; \
		exit 2; \
	fi; \
	if [ -z "$$INSTALL_BIN_VERSION_ARG" ]; then \
		INSTALL_BIN_VERSION_ARG="--version"; \
	fi; \
	if ! check_and_download_bin "$$INSTALL_BIN_URL" "$$INSTALL_BIN_NAME" "$$INSTALL_BIN_VERSION_ARG" "$$INSTALL_BIN_VERSION"; then \
		exit 1; \
	fi

install/jq: export INSTALL_BIN_NAME = $(JQ_BIN_NAME)
install/jq: export INSTALL_BIN_VERSION = $(JQ_VERSION)
install/jq: export INSTALL_BIN_URL = https://github.com/jqlang/jq/releases/download/jq-@BIN_VER@/jq-$(JQ_PLATFORM_ARCH)
install/jq: ## jq https://github.com/jqlang/jq
	@$(MAKE) install/binary

install/yq: export INSTALL_BIN_NAME = $(YQ_BIN_NAME)
install/yq: export INSTALL_BIN_VERSION = $(YQ_VERSION)
install/yq: export INSTALL_BIN_URL = https://github.com/mikefarah/yq/releases/download/v@BIN_VER@/yq_@BIN_OS@_@BIN_ARCH@
install/yq: ## yq https://github.com/mikefarah/yq
	@$(MAKE) install/binary

install/common/all: install/jq install/yq ## Install common deps

##@ Common. Cleanup

clean/common: ## Remove common binaries from local bin dir
	@rm -fv "$(JQ_BIN_FULL)"
	@rm -fv "$(YQ_BIN_FULL)"

.PHONY: bin check/installed/bin check/installed/tar check/installed/find check/installed/sha256sum check/installed/curl check/installed/docker install/binary install/jq install/yq install/common/all clean/common check/bin/linked/dynamic check/bin/linked/static