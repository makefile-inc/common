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
#       $1 - binary name without path
#       $2 - version argument passed in binary for extract version
#       $3 - version to check. Function uses grep for match version
#       $4 - url to download. Can be contains next string for substitution 
#          @BIN_VER@  - replace to version passed via $3
#          @BIN_OS@   - replace to calculated os name $(OS_CALCULATED) (linux or darwin) 
#          @BIN_ARCH@ - replace to calculated os name $(ARCH_CALCULATED) (amd64 or arm64) 
#   if binary present and executable and have correct version returns zero code, otherwise - 1, invalid args - 2
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
#	    @${INCLUDE_CHECK_BINARY} \
#       if ! check_binary jq "--version" "1.8.1"; then \
#	      echo "Download..."; \
#	    fi
#   bin/jq:
#	    @${INCLUDE_CHECK_BINARY} \
# 		url="https://github.com/jqlang/jq/releases/download/jq-@BIN_VER@/jq-$(JQ_PLATFORM_ARCH)"
#       if ! check_and_download_bin jq "--version" "1.8.1" "$$url"; then \
#	      echo "Download..."; \
#	    fi
#   bin/yq:
#	    @${INCLUDE_CHECK_BINARY} \
# 		url="https://github.com/mikefarah/yq/releases/download/v@BIN_VER@/yq_@BIN_OS@_@BIN_ARCH@"; \
#       if ! check_and_download_bin jq "--version" "4.0.0" "$$url"; then \
#	      exit 1; \
#	    fi
# Can be included multiple times because sh redeclare function without error
define INCLUDE_CHECK_BINARY
${INCLUDE_ECHO} \
function check_binary() { \
	binary="$$1"; \
	version_arg="$$2"; \
	version="$$3"; \
\
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
\
	binary_full_path="$(BINARIES_PATH)/$${binary}"; \
\
	if [ ! -x "$$binary_full_path" ]; then \
  		echo_warn "$$binary_full_path not exists or not executable"; \
  		return 1; \
	fi; \
\
	if ! got_bin_ver="$$("$$binary_full_path" "$$version_arg")"; then \
  		echo_err "${RED_COLOR}Version of $$binary_full_path cannot extracted!${NO_COLOR}"; \
  		return 2; \
	fi; \
\
	if ! grep -q "$$version" <<<"$$got_bin_ver"; then \
  		echo_warn "Version of $$binary_full_path not match $$version Version is $$got_bin_ver"; \
  		return 1; \
	fi; \
	echo_info "$$binary_full_path with $$version already installed"; \
	return 0; \
}; \
function check_and_download_bin() { \
	binary="$$1"; \
	version_arg="$$2"; \
	version="$$3"; \
	passed_url="$$4"; \
	if ! check_binary "$$binary" "$$version_arg" "$$version"; then \
		ret_code="$$?"; \
		if [ "$$ret_code" -eq 2 ]; then \
			echo_err "Incorrect args for check_and_download_bin"; \
			return 2; \
		fi; \
		url="$$passed_url"; \
		sub_ver="gsub(\"@BIN_VER@\", \"$$version\")"; \
		url="$$(echo "$$url" | ${AWK_BIN} "$$sub_ver")"; \
		if [ -z "$$url" ]; then \
			url="$$passed_url"; \
		fi; \
		passed_url="$$url"; \
		sub_arch="gsub(\"@BIN_ARCH@\", \"$(ARCH_CALCULATED)\")"; \
		url="$$(echo "$$url" | ${AWK_BIN} "$$sub_arch")"; \
		if [ -z "$$url" ]; then \
			url="$$passed_url"; \
		fi; \
		passed_url="$$url"; \
		sub_os="gsub(\"@BIN_OS@\", \"$(OS_CALCULATED)\")"; \
		url="$$(echo "$$url" | ${AWK_BIN} "$$sub_os")"; \
		if [ -z "$$url" ]; then \
			url="$$passed_url"; \
		fi; \
		dest="$(BINARIES_PATH)/$${binary}"; \
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
#   	$(shell $(call CHECK_BINARY,$(JQ_BIN_NAME),--version,$(JQ_VERSION)))
#		@if [ "$(.SHELLSTATUS)" -ne 0 ]; then \
#			set -Eeuo pipefail; \
#			dest="$(JQ_BIN_FULL)"; \
#			echo -e "${GREEN_COLOR}Install yq for go to $$dest${NO_COLOR}"; \
#			curl -sSfLo "$$dest" https://github.com/jqlang/jq/releases/download/jq-$(JQ_VERSION)/jq-$(JQ_PLATFORM_ARCH); \
#			chmod +x "$$dest"; \
#		fi
define CHECK_BINARY
${INCLUDE_CHECK_BINARY} \
if ! check_binary "$(1)" "$(2)" "$(3)"; then \
  exit 1; \
fi; \
exit 0;
endef

##@ Common. Directories

bin: ## Make bin directory
	@##~ SET_BINARIES_PATH=PATH - dir utils binaries. By default $(CURDIR)/bin
	@mkdir -p "$(BINARIES_PATH)"

##@ Common. Checks binary is installed in system

check/installed/curl: ## curl
	@if ! command -v curl > /dev/null; then \
        echo "${RED_COLOR}curl not installed${NO_COLOR}"; \
        exit 1; \
    fi

check/installed/docker: ## docker
	@if ! command -v docker > /dev/null; then \
        echo "${RED_COLOR}docker not installed${NO_COLOR}"; \
        exit 1; \
    fi

##@ Common. Install binary to local bin dir

install/binary: bin check/installed/curl ## install (download) binary with provided version to BINARIES_PATH (./bin dir by default)
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
	if ! check_and_download_bin "$$INSTALL_BIN_NAME" "$$INSTALL_BIN_VERSION_ARG" "$$INSTALL_BIN_VERSION" "$$INSTALL_BIN_URL"; then \
		exit 1; \
	fi

YQ_BIN_NAME  = yq
YQ_BIN_FULL  = $(BINARIES_PATH)/$(YQ_BIN_NAME)

JQ_BIN_NAME = jq
JQ_BIN_FULL = $(BINARIES_PATH)/$(JQ_BIN_NAME)

ifeq ($(OS_CALCULATED), $(OS_LINUX))
	JQ_PLATFORM = $(OS_LINUX)
else ifeq ($(OS_CALCULATED), $(OS_MACOS))
	JQ_PLATFORM = macos
endif

JQ_PLATFORM_ARCH = $(JQ_PLATFORM)-$(ARCH_CALCULATED)

install/jq: export INSTALL_BIN_NAME = $(JQ_BIN_NAME)
install/jq: export INSTALL_BIN_VERSION = $(JQ_VERSION)
install/jq: export INSTALL_BIN_URL = https://github.com/jqlang/jq/releases/download/jq-@BIN_VER@/jq-$(JQ_PLATFORM_ARCH)
install/jq: install/binary ## jq https://github.com/jqlang/jq

install/yq: export INSTALL_BIN_NAME = $(YQ_BIN_NAME)
install/yq: export INSTALL_BIN_VERSION = $(YQ_VERSION)
install/yq: export INSTALL_BIN_URL = https://github.com/mikefarah/yq/releases/download/v@BIN_VER@/yq_@BIN_OS@_@BIN_ARCH@
install/yq: install/binary ## yq https://github.com/mikefarah/yq

##@ Common. Cleanup

clean/common: ## Remove common binaries from local bin dir
	rm -f "$(JQ_BIN_FULL)"
	rm -f "$(YQ_BIN_FULL)"