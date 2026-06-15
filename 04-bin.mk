YQ_BIN_NAME  = yq
YQ_BIN_FULL  = $(BINARIES_PATH)/$(YQ_BIN_NAME)

JQ_BIN_NAME = jq
JQ_BIN_FULL = $(BINARIES_PATH)/$(JQ_BIN_NAME)

ifeq ($(OS_NAME), Linux)
	YQ_PLATFORM = linux
	JQ_PLATFORM = linux
else ifeq ($(OS_NAME), Darwin)
	YQ_PLATFORM = darwin
	JQ_PLATFORM = macos
endif

ifeq ($(PLATFORM_NAME), x86_64)
	YQ_PLATFORM_ARCH = $(YQ_PLATFORM)_amd64
	JQ_PLATFORM_ARCH = $(JQ_PLATFORM)-amd64
else ifeq ($(PLATFORM_NAME), arm64)
	YQ_PLATFORM_ARCH = $(YQ_PLATFORM)_arm64
	JQ_PLATFORM_ARCH = $(JQ_PLATFORM)-arm64
endif

define CHECK_BINARY
binary="$(1)"; \
version_arg="$(2)"; \
version="$(3)"; \
\
if [ -z "$$binary" ]; then \
  echo "binary not passed as first CHECK_BINARY define arg" >&2; \
  exit 1; \
fi; \
if [ -z "$$version_arg" ]; then \
  echo "binary version argument not passed as second CHECK_BINARY define arg" >&2; \
  exit 1; \
fi; \
if [ -z "$$version" ]; then \
  echo "target binary version not passed as third CHECK_BINARY define arg" >&2; \
  exit 1; \
fi; \
\
binary_full_path="$(BINARIES_PATH)/$${binary}"; \
\
if [ ! -x "$$binary_full_path" ]; then \
  echo "$$binary_full_path not exists or not executable" >&2; \
  exit 1; \
fi; \
\
if ! got_bin_ver="$$("$$binary_full_path" "$$version_arg")"; then \
  echo -e "${RED_COLOR}Version of $$binary_full_path cannot extracted!${NO_COLOR}" >&2; \
  exit 2; \
fi; \
\
if ! grep -q "$$version" <<<"$$got_bin_ver"; then \
  echo "Version of $$binary_full_path not match $$version Version is $$got_bin_ver" >&2; \
  exit 1; \
fi; \
exit 0
endef

##@ Common. Directories

bin: ## Make bin directory
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

install/jq: bin check/installed/curl ## jq https://github.com/jqlang/jq
	$(shell $(call CHECK_BINARY,$(JQ_BIN_NAME),--version,$(JQ_VERSION)))
	@if [ "$(.SHELLSTATUS)" -ne 0 ]; then \
		set -Eeuo pipefail; \
		dest="$(JQ_BIN_FULL)"; \
		echo -e "${GREEN_COLOR}Install jq for go to $$dest${NO_COLOR}"; \
		curl -sSfLo "$$dest" https://github.com/jqlang/jq/releases/download/jq-$(JQ_VERSION)/jq-$(JQ_PLATFORM_ARCH); \
		chmod +x "$$dest"; \
	fi

install/yq: bin check/installed/curl ## yq https://github.com/mikefarah/yq
	$(shell $(call CHECK_BINARY,$(YQ_BIN_NAME),--version,$(YQ_VERSION)))
	@if [ "$(.SHELLSTATUS)" -ne 0 ]; then \
		set -Eeuo pipefail; \
		dest="$(YQ_BIN_FULL)"; \
		echo -e "${GREEN_COLOR}Install yq for go to $$dest${NO_COLOR}"; \
		curl -sSfLo "$$dest" https://github.com/mikefarah/yq/releases/download/v$(YQ_VERSION)/yq_$(YQ_PLATFORM_ARCH); \
		chmod +x "$$dest"; \
	fi

##@ Common. Cleanup

clean/common: ## Remove common binaries from local bin dir
	rm -f "$(JQ_BIN_FULL)"
	rm -f "$(YQ_BIN_FULL)"