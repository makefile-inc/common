ifndef SET_BUILD_PATH
  SET_BUILD_PATH = $(CURDIR)/build
endif

BUILD_PATH = $(abspath $(SET_BUILD_PATH))

# INCLUDE_BUILD_OUT_NAME - add next sh function:
#   build_out_name - print binary name for build
#     Arguments:
#       $1 - project name. Required. Also can be passed via env PROJECT_NAME
#       $2 - platform (os) name. Optional. By default get from $(OS_CALCULATED)
#            Also can be passed via env BUILD_OS
#            Should be linux or darwin
#       $3 - arch name. Optional. By default get from $(ARCH_CALCULATED)
#            Also can be passed via env BUILD_ARCH
#            Should be amd64 or arm64
#   print in format ${project}-${platform}-${arch}
#   if have errors - returns 1 and output error to stderr
# Example include:
#   @${INCLUDE_BUILD_OUT_NAME} \ - slash is required!
# Example:
#   include *.mk
#   export BUILD_PROJECT = test
#   build/name/default:
#	    @${INCLUDE_BUILD_OUT_NAME} \
#       if ! name="$$(build_out_name)"; then \
#	      exit 1; \
#	    fi; \
#       echo "$$name"
#   build/name/mac: export BUILD_OS = $(OS_MACOS)
#   build/name/mac: export BUILD_ARCH = $(ARCH_ARM)
#   build/name/mac:
#	    @${INCLUDE_BUILD_OUT_NAME} \
#       if ! name="$$(build_out_name)"; then \
#	      exit 1; \
#	    fi; \
#       echo "$$name"
# Can be included multiple times because sh redeclare function without error
define INCLUDE_BUILD_OUT_NAME
${INCLUDE_ECHO} \
function build_out_name() { \
	project="$$1"; \
	platform="$$2"; \
	arch="$$3"; \
	if [ -z "$$project" ]; then \
  		if [ -n "$$PROJECT_NAME" ]; then \
			project="$$PROJECT_NAME"; \
		else \
			echo_err "project name not passed via first arg or PROJECT_NAME env"; \
			return 1; \
  		fi; \
	fi; \
	if [ -z "$$platform" ]; then \
  		if [ -n "$$BUILD_OS" ]; then \
			platform="$$BUILD_OS"; \
  		else \
			platform="$(OS_CALCULATED)"; \
  		fi; \
	fi; \
	platform_found=""; \
	for platform_i in $(AVAILABLE_OSES); do \
		if [ "$$platform_i" = "$$platform" ]; then \
			platform_found="true"; \
			break; \
		fi; \
	done; \
	if [ -z "$$platform_found" ]; then \
		echo_err "incorrect platform '$$platform' should be: $(AVAILABLE_PLATFORMS)"; \
		return 1; \
	fi; \
	if [ -z "$$arch" ]; then \
  		if [ -n "$$BUILD_ARCH" ]; then \
			arch="$$BUILD_ARCH"; \
  		else \
			arch="$(ARCH_CALCULATED)"; \
  		fi; \
	fi; \
	arch_found=""; \
	for arch_i in $(AVAILABLE_ARCHS); do \
		if [ "$$arch_i" = "$$arch" ]; then \
			arch_found="true"; \
			break; \
		fi; \
	done; \
	if [ -z "$$arch_found" ]; then \
		echo_err "incorrect arch '$$arch' should be: $(AVAILABLE_ARCHS)"; \
		return 1; \
	fi; \
	echo -n "$${project}-$${platform}-$${arch}"; \
	return 0; \
};
endef

##@ Common. Build

build/dir: ## Make build directory
	@##~ SET_BUILD_PATH=PATH - dir for output build binaries. By default $(CURDIR)/build
	@mkdir -p "$(BUILD_PATH)"

_build/general: build/dir
	@${INCLUDE_BUILD_OUT_NAME} \
	if [ -z "$$BUILD_TARGET" ]; then \
		exit_with_err "BUILD_TARGET is not passed"; \
	fi; \
	if ! bin_name="$$(build_out_name)"; then \
		exit_with_err "Cannot extract build out name"; \
	fi; \
	export OUT_BIN="$(BUILD_PATH)/$$bin_name"; \
	export BUILD_OS="$$BUILD_OS"; \
	export BUILD_ARCH="$$BUILD_ARCH"; \
	${RUN_WITH_DURATION} "$$BUILD_TARGET" "Build $$bin_name"

build/current: export BUILD_OS = $(OS_CALCULATED)
build/current: export BUILD_ARCH = $(ARCH_CALCULATED)
build/current: _build/general ## Do build target for current os and arch
	@##~ PROJECT_NAME=NAME - name of project
	@##~ BUILD_TARGET=NAME - name of target for build
	@##~   Pass args to target:
	@##~     OUT_BIN - output binary
	@##~     BUILD_OS - target os (linux, darwin)
	@##~     BUILD_ARCH - target arch (amd64, arm64)

build/linux: export BUILD_OS = $(OS_LINUX)
build/linux: export BUILD_ARCH = $(ARCH_CALCULATED)
build/linux: _build/general ## Do build target for linux os and current arch
	@##~ PROJECT_NAME=NAME - name of project
	@##~ BUILD_TARGET=NAME - name of target for build
	@##~   Pass args to target:
	@##~     OUT_BIN - output binary
	@##~     BUILD_OS - target os linux
	@##~     BUILD_ARCH - target arch (amd64, arm64)


build/linux/all: export BUILD_OS = $(OS_LINUX)
build/linux/all: ## Do build target for linux for all arch
	@##~ PROJECT_NAME=NAME - name of project
	@##~ BUILD_TARGET=NAME - name of target for build
	@##~   Pass args to target:
	@##~     OUT_BIN - output binary
	@##~     BUILD_OS - target os linux
	@##~     BUILD_ARCH - target arch (amd64, arm64)
	@$(MAKE) _build/general BUILD_ARCH=$(ARCH_AMD)
	@$(MAKE) _build/general BUILD_ARCH=$(ARCH_ARM)

build/mac: export BUILD_OS = $(OS_MACOS)
build/mac: export BUILD_ARCH = $(ARCH_ARM)
build/mac: _build/general ## Do build target for linux os and arm arch
	@##~ PROJECT_NAME=NAME - name of project
	@##~ BUILD_TARGET=NAME - name of target for build
	@##~   Pass args to target:
	@##~     OUT_BIN - output binary
	@##~     BUILD_OS - target os darwin
	@##~     BUILD_ARCH - target arch arm64

build/mac/all: export BUILD_OS = $(OS_MACOS)
build/mac/all: ## Do build target for mac for all arch
	@##~ PROJECT_NAME=NAME - name of project
	@##~ BUILD_TARGET=NAME - name of target for build
	@##~   Pass args to target:
	@##~     OUT_BIN - output binary
	@##~     BUILD_OS - target os linux
	@##~     BUILD_ARCH - target arch (amd64, arm64)
	@$(MAKE) _build/general BUILD_ARCH=$(ARCH_AMD)
	@$(MAKE) _build/general BUILD_ARCH=$(ARCH_ARM)

build/all: build/linux/all  build/mac/all ## Do build target for mac and linux for all arch
	@##~ PROJECT_NAME=NAME - name of project
	@##~ BUILD_TARGET=NAME - name of target for build
	@##~   Pass args to target:
	@##~     OUT_BIN - output binary
	@##~     BUILD_OS - target os (linux, darwin)
	@##~     BUILD_ARCH - target arch (amd64, arm64)