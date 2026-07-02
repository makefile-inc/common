# common

Common makefiles includes for another Makefile and target repos

## Dependencies

Should be installed:
- `bash` >= 4.X.X
- `make`
- `awk`. For MacOS should installed `gawk`
- `curl` - it needs for download dependencies. By default, targes that needs curl
   check that its installed
- now we support only `Linux` and `MacOS` on `x86` and `ARM` 64-bits.

### Bash caveats
By default, includes use `bash` as shell consumed with `/usr/bin/env bash`.

#### Alpine

If you are using `alpine` containers, you should install bash with next command:

```sh
apk update && apk add --no-cache bash
```

By default, `alpine` does not conains bash.

#### MacOS

MacOS install old bash version `3.2.x` by default.
It is not support many features like associative arrays.
You should install bash (for example with [brew](http://brew.sh/)):

```bash
brew install bash
```

Another deps can be installed with:

```bash
brew install curl
brew install gawk
```

## Install

### Manual

You can copy all files in your own repo (for example in subdir `makefile-common`) 
and include in root Makefile in the next way:

```Makefile
include $(CURDIR)/makefile-common/include.mk.inc
```

### As submodule

Add submodule:

```bash
git submodule add git@github.com:makefile-inc/common.git makefile-common
```

Checkout to target version:

```
pushd .
cd makefile-common
git fetch -a && git checkout v0.2.0 && git pull
popd
```

Include in root Makefile in the next way:

```Makefile
include $(CURDIR)/makefile-common/include.mk.inc
```

**WARNING! If you use submodule and github actions, add to checkout action checkout submodules `submodules: "true"`, like:**
```yaml
...
    steps:
      - &checkout_step
        name: Checkout
        uses: actions/checkout@v6.0.2
        with:
          fetch-depth: 0
          submodules: "true"
          ref: ${{ github.event.pull_request.head.sha }}
...
``` 

## Pre-definitions

Includes contain some variables and make definitions.

## No print derictories

Because includes uses recurcive make calls 00-common.mk add `--no-print-directory` argument:

```Makefile
MAKEFLAGS += --no-print-directory
```

### Variables

Now inclues files in `common` repo contains next predifined variables:
- `BINARIES_PATH` - dir to store local helper binaries. By default `$(CURDIR)/bin`.
  Can be redeclared with `SET_BINARIES_PATH` variable.
  Also, includes add this path to `PATH` env when running make. 
- Color variables, using for color output in terminal:
  - `RED_COLOR`    - ${\color{red}red}$
  - `GREEN_COLOR`  - ${\color{green}green}$
  - `YELLOW_COLOR` - ${\color{yellow}yellow}$
  - `CYAN_COLOR`   - ${\color{cyan}cyan}$
  - `BOLD_COLOR`   - **bold**
  - `NO_COLOR`     - end coloring output.
  Can be used in Make file like:
  ```Makefile
  error:
  	echo -e "${RED_COLOR}Error!!!${NO_COLOR}"; \
  	exit 1; \
  ```
- `OS_LINUX` - linux (can be used with `OS_CALCULATED`)
- `OS_MACOS` - darwin (can be used with `OS_CALCULATED`)
- `ARCH_AMD` - amd64  (can be used with `ARCH_CALCULATED`)
- `ARCH_ARM` - arm64   (can be used with `ARCH_CALCULATED`)
- `ARCH_CALCULATED` - result of command `uname -m` architicture (like `amd64`, `arm64`)
- `OS_CALCULATED` - OS name `linux` or `darwin` for MacOS
- `AWK_BIN` - awk binary name. For linux `awk`, for MacOS `gawk`
- `JQ_BIN_FULL` - full path to local installed [jq](https://github.com/jqlang/jq)
- `YQ_BIN_FULL` - full path to local installed [yq](https://github.com/mikefarah/yq)
- `BUILD_PATH` - directory to output builds (by default `./build`). Can be redeclared with `SET_BUILD_PATH`

### Definitions

#### Callable

Next definitions can call in makefile with `$(shell $(call ...))` or `$(call ...)`:
- `CHECK_BINARY` - check that local binary installed and have target version.  
  Params:
  - `$(1)` - binary name in `BINARIES_PATH` dir.
  - `$(2)` - binary argument for consume current binary version.
  - `$(3)` - target binary version, that will grep from version call.

  When def called with shell, prepared script retuns none-zero code
  if binary not installed or not have target version.

  Example:
  ```Makefile
  install/my-bin: bin check/installed/curl
  	$(shell $(call CHECK_BINARY,my-bin,--version,0.1.0))
		@if [ "$(.SHELLSTATUS)" -ne 0 ]; then \
			set -Eeuo pipefail; \
			dest="$(BINARIES_PATH/my-bin)"; \
			echo -e "${GREEN_COLOR}Install my-bin to $$dest${NO_COLOR}"; \
			curl ...; \
			chmod +x "$$dest"; \
		fi
   ```
- `RUN_WITH_CLEANUP` - run target and call another tharget after run first (with or withouth error).
  Params:
   - `$(1)` - target for run.
   - `$(2)` - cleanup target.

  Example:
  ```Makefile
  test/run-with-cleanup/ok:
		@$(call RUN_WITH_CLEANUP,test/sleep-exec-ok,test/cleanup/run)

  test/run-with-cleanup/fail:
		@$(call RUN_WITH_CLEANUP,test/sleep-exec-fail,test/cleanup/run)
  ```

#### Scripts definitions

This definitions can be used inside makefile targets as makefile varibles, like:
```Makefile
do/some:
	@out="$$(${DEFINITION} "param1" "param2")"; \
	echo "$$out"
```

- `NOW_MICROSECONDS` - call date and return to stdout current unix-time with microseconds.
   No params. Userfull with `HUMAN_DURATION_MICROSECONDS`.
- `HUMAN_DURATION_MICROSECONDS` output duration microseconds in human way.
   Params:
   - `$1` - start microsends unix-time (can get with `NOW_MICROSECONDS`)
   - `$2` - end microsends unix-time (can get with `NOW_MICROSECONDS`)

   Output can be like:

   ```
   00.001000s
   01.001103s
   01m 41.001103s
   27h 48m 21.001103s
   ```

  Example:
  ```MakeFile
  test/duration:
		@start="$$(${NOW_MICROSECONDS})"; \
		sleep 2; \
		end="$$(${NOW_MICROSECONDS})"; \
		dur="$$(${HUMAN_DURATION_MICROSECONDS} "$$start" "$$end")"; \
		echo "Duration $$dur"  
  ```
- `RUN_WITH_DURATION` - call another tharget, calculate duration time and print duration.
  Warning! Because whe use call another bins in bash duration of target can little different 
  from run standalone.
  Params:
  - `$1` - makefile target
  - `$2` - humman name of target for print.

  If target exit with zero code duration will print with green color, otherwise with red.
  
  Example:
  ~~~MakeFile
  test/sleep-exec-ok:
		@sleep 2; \
		exit 0
  test/run-with-duration/ok:
		@${RUN_WITH_DURATION} "test/sleep-exec-ok" "Do with ok"
  ~~~

  Example outputs:

  $ make test/run-with-duration/ok

  make[1]: Entering directory '/home/nick/src/makefile.inc/common'

  make[1]: Leaving directory '/home/nick/src/makefile.inc/common'
  
  ${\color{green}Do \space with \space ok \space 02.023318s}$

    
  $ make test/run-with-duration/fail

  make[1]: Entering directory '/home/nick/src/makefile.inc/common'

  make[1]: Leaving directory '/home/nick/src/makefile.inc/common'
  
  ${\color{red}Do \space with \space fail \space 02.023318s}$

#### Scripts inludes

Next definitions add bash functions definitions, which can cal in one line bash targets, like:
```Makefile
_test/echo:
	@${INCLUDE_ECHO} \
	echo_info "Done"; \
	echo_warn "Warn"; \
	echo_err "Error!"
```

**WARNING! When use definition you SHOULD use `\` in the end of line for prevent break one-line script!**

Next definitions can be included multiple times because sh redeclare function without error.

- `INCLUDE_ECHO` - add next sh functions:
    - `echo_err`      - print to stderr first argument with red color
    - `echo_info`     - print to stderr first argument with green color
    - `echo_warn`     - print to stderr first argument with yellow color
    - `exit_with_err` - print to stderr first argument with red color 
                        and exit with non-zero exit code (default 1, maybe passed  with second arg)

  Example:
  ```Makefile
  include *.mk
  test/echo:
		@${INCLUDE_ECHO} \
		echo_info "Done"; \
		echo_warn "Warn"; \
		echo_err "Error!";
  test/error_exit_default:
		@${INCLUDE_ECHO} \
		exit_with_err "Fail!"
  test/error_exit:
		@${INCLUDE_ECHO} \
  	exit_with_err "Fail!" 3
  ```

- `INCLUDE_CHECK_BINARY` - add next sh function (`INCLUDE_ECHO` also included):
    - `check_binary` - check that binary is exists in `BINARIES_PATH` and executable and have correct version.
        Arguments:
        - `$1` - binary name without path
        - `$2` - version argument for binary for extract version
        - `$3` - version to check. Function uses grep for match version
        if binary present and executable and have correct version returns zero code, otherwise - 1, invalid args - 2
    - `check_and_download_bin` - check that binary is exists in `BINARIES_PATH` and executable and have correct version
                                 if not - download.
        Arguments:
        - `$1` - binary name without path
        - `$2` - version argument passed in binary for extract version
        - `$3` - version to check. Function uses grep for match version
        - `$4` - url to download. Can be contains next string for substitution
               - `@BIN_VER@ ` - replace to version passed via `$3`
               - `@BIN_OS@`   - replace to calculated os name `$(OS_CALCULATED)` (linux or darwin) 
               - `@BIN_ARCH@` - replace to calculated os name `$(ARCH_CALCULATED)` (amd64 or arm64) 
        if binary present and executable and have correct version returns zero code, otherwise - 1, invalid args - 2
  Example:
  ```Makefile
  include *.mk
  ifeq ($(OS_CALCULATED), $(OS_LINUX))
  	JQ_PLATFORM = OS_LINUX
  else ifeq ($(OS_CALCULATED), $(OS_MACOS))
		JQ_PLATFORM = macos
  endif
  JQ_PLATFORM_ARCH = $(JQ_PLATFORM)-$(ARCH_CALCULATED)
  bin/jq/check:
		@${INCLUDE_CHECK_BINARY} \
  	if ! check_binary jq "--version" "1.8.1"; then \
			echo "Download..."; \
		fi
  bin/jq:
  	@${INCLUDE_CHECK_BINARY} \
  	url="https://github.com/jqlang/jq/releases/download/jq-@BIN_VER@/jq-$(JQ_PLATFORM_ARCH)"
  	if ! check_and_download_bin jq "--version" "1.8.1" "$$url"; then \
			echo "Download..."; \
		fi
  bin/yq:
		@${INCLUDE_CHECK_BINARY} \
  	url="https://github.com/mikefarah/yq/releases/download/v@BIN_VER@/yq_@BIN_OS@_@BIN_ARCH@"; \
  	if ! check_and_download_bin jq "--version" "4.0.0" "$$url"; then \
			exit 1; \
		fi
  ```

- `INCLUDE_BUILD_OUT_NAME` - add next sh function:
  - `build_out_name` - print binary name for build.
      Arguments:
      - `$1` - project name. Required. Also can be passed via env `PROJECT_NAME`.
      - `$2` - platform (os) name. Optional. By default get from `$(OS_CALCULATED)`.
             Also can be passed via env `BUILD_OS`. Should be `linux` or `darwin`.
      - `$3` - arch name. Optional. By default get from `$(ARCH_CALCULATED)`.
             Also can be passed via env `BUILD_ARCH`
             Should be `amd64` or `arm64`
      Print in format `${project}-${platform}-${arch}`.
      If have errors - returns 1 and output error to stderr
      Example:
      ```Makefile
      include *.mk
      export BUILD_PROJECT = test
      build/name/default:
	    @${INCLUDE_BUILD_OUT_NAME} \
      	if ! name="$$(build_out_name)"; then \
	    		exit 1; \
	    	fi; \
      	echo "$$name"
      build/name/mac: export BUILD_OS = $(OS_MACOS)
      build/name/mac: export BUILD_ARCH = $(ARCH_ARM)
      build/name/mac:
	    	@${INCLUDE_BUILD_OUT_NAME} \
      	if ! name="$$(build_out_name)"; then \
	    		exit 1; \
	    	fi; \
      	echo "$$name"

## Targets

### Help

- `help` - print help for all marked targets in root Makefile and all includes. Set as default target.
  See instruction for add help and examples [below](#add-targets-to-help-output)

### Third-party binaries

- `bin` - create `BINARIES_PATH`
- `install/binary` - check that binary is exists in `BINARIES_PATH` and executable and have correct version, if not - download.
  **WARNING! Call this target with recurcive call make to prevent skip run target in another targets multiple times!**
  Params:
  - `INSTALL_BIN_NAME`=*NAME* - name of binary in `BINARIES_PATH`
	- `INSTALL_BIN_VERSION`=*VERSION* - version of binary
	- `INSTALL_BIN_VERSION_ARG`=*ARG* - version argument passed in binary for extract version, by default `--version`
	- `INSTALL_BIN_URL`=*URL* - url for download binary. Can contains: 
	  - `@BIN_VER@`  - replace to version passed via `INSTALL_BIN_VERSION` 
	  - `@BIN_OS@`   - replace to calculated os name `$(OS_CALCULATED)` (linux or darwin)
	  - `@BIN_ARCH@` - replace to calculated os name `$(ARCH_CALCULATED)` (amd64 or arm64)
	  For example: `https://github.com/mikefarah/yq/releases/download/v@BIN_VER@/yq_@BIN_OS@_@BIN_ARCH@`

    Example:
    ```Makefile
    install/yq: export INSTALL_BIN_NAME = $(YQ_BIN_NAME)
    install/yq: export INSTALL_BIN_VERSION = $(YQ_VERSION)
    install/yq: export INSTALL_BIN_URL = https://github.com/mikefarah/yq/releases/download/v@BIN_VER@/yq_@BIN_OS@_@BIN_ARCH@
    install/yq: ## yq https://github.com/mikefarah/yq
    	@$(MAKE) install/binary # USE MAKE FOR PREVENT SKIP TARGET!
    ```
- `check/installed/curl` - check that [curl](https://curl.se/) is installed in the system
- `check/installed/docker` - check that [docker](https://www.docker.com/) is installed in the system
- `install/jq` - install [jq](https://github.com/jqlang/jq) to local bin path
- `install/yq` - install [yq](https://github.com/mikefarah/yq) to local bin path
- `clean/common` - remove binaries installed with common package (`yq` and `jq` now)

### Build

Next targets are generic targets for build binaries. Before run creates `BUILD_PATH` dir.
Every target take next params:
- `PROJECT_NAME` - name of preject
- `BUILD_TARGET` - make target for run.

Targets pass to `BUILD_TARGET` next params:
- `OUT_BIN`    - ouptput binary file path in `./build` (can be redeclared with `SET_BUILD_PATH`). 
                 File has next format `$(BUILD_PATH)/$(PROJECT_NAME)-OS-ARCH`
- `BUILD_OS`   - os for build (linux or darwin)
- `BUILD_ARCH` - build arch (amd64 or arm64).

Targets:
- `build/dir`       - creates `BUILD_PATH` dir
- `build/current`   - build binary for current machine os and arch
- `build/linux`     - build binary for current machine arch linux
- `build/linux/all` - build binary for linux and all supported arch'es
- `build/mac`       - build binary for MacOS and arm64 arch
- `build/mac/all`   - build binary for MacOS and all supported arch'es
- `build/all`       - build binary for all supported os'es and arch'es
- `clean/build`     - remove `BUILD_PATH` dir.

### Git

- `common/git/check/gitignore` - check that gitignore file contains another gitignore files rules.
   Userfull for checking in another includes repos and rott makefile that all gitignore rules
   were added to root `.gitignore` file.
   Params:
   - `ROOT_GITIGNORE`=*PATH* - path to gitignore file for check (root .gitignore). Default `$(CURDIR)/.gitignore`
   - `GITIGNORES_WITH_REQUIRED_RULES`=*PATHS...* - comma separated paths to gitignore files that should contains `ROOT_GITIGNORE`.
- `common/git/check/has-diff` - check that repo has difference
  Params:
  - `TARGET_NAME`    - if passed run make target before git check. Optional
  - `FILES_TO_CHECK` - comma separated paths regexp for check. Optional
  - `FILES_TO_SKIP`  - comma separated paths regexp for skip. Optional. Has higer priority.
  Examples:
  ```bash
  make common/git/check/has-diff FILES_TO_SKIP=".*.mk" FILES_TO_CHECK=".*.mk" TARGET_NAME="build/dir"
  make common/git/check/has-diff FILES_TO_SKIP=".*.md,.*.mk" TARGET_NAME="build/dir"
  make common/git/check/has-diff FILES_TO_CHECK=".*.mk"
  make common/git/check/has-diff
  ```
  ```Makefile
  include *.mk
  go/tidy:
  	go mod tidy
  
  check/no-tidy: export FILES_TO_CHECK=go.mod,go.sum
  check/no-tidy: export TARGET_NAME=go/tidy
  check/no-tidy: common/git/check/has-diff
  ```

### Add targets to help output

#### Example output:

Usage: make ${\color{yellow}target}$ OPTION="${\color{cyan}value}$"

  ${\color{yellow}help}$&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Show this message
<br>
<br>
**Common. Git**
<br>
<br>
  ${\color{yellow}target}$&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;  Check that gitignore file contains another gitignor files rules.<br>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;              ${\color{cyan}PARAM1=val \space First \space param}$<br>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;              ${\color{cyan}PARAM2=val \space Second \space param}$

#### Add target to help

After definition target add `## `&nbsp; and description of target after `## `&nbsp; like:

```Makefile
target: ## Target description
	@echo "Hello, world!"
```

If target not marked with `## Description` this target will no output in help!

#### Add options for target

After definition and description add `@##~ ` &nbsp; and parameter description after `##~ `.
For multiple params, add multiple `@##~ ` &nbsp; for every param separated by new line.
Example:

```Makefile
target: ## Target description
	@##~ OP_NAME=name - operation name
	@##~ HELLO_NAME=name - name for output hello
	@echo "Hello, $$HELLO_NAME! Start operation $${OP_NAME}..."
```

#### Group targets

You can add header for group of targets. For it, add `##@ ` &nbsp; comment like:
```Makefile
##@ Build

build/linux: ## Build binary for linux os
	@echo "Build linux..."
build/mac: ## Build binary for linux mac
	@echo "Build mac..."

##@ Cleanup

cleanup/linux: ## Cleanup linux build artifacts
	@rm -rm build/linux
cleanup/mac: ## Cleanup mac build artifacts
	@rm -rm build/mac
cleanup: cleanup/linux cleanup/mac ## Cleanup all build artifacts
```
