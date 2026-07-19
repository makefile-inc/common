# common

Common makefiles includes for another Makefile and target repos

## Dependencies

Should be installed:
- `bash` >= 4.2
- `make`
- `awk`. For MacOS should installed `gawk`
- `curl` - it needs for download dependencies. By default, targets that needs curl
   check that its installed
- `find`. For MacOS should installed `gfind`
- `tar`. For MacOS should installed `gtar`
- now we support only `Linux` and `MacOS` on `x86` and `ARM` 64-bits.

### Bash caveats
By default, includes use `bash` as shell consumed with `/usr/bin/env bash`.

#### Alpine

If you are using `alpine` containers, you should install bash with next command:

```sh
apk update && apk add --no-cache bash
```

By default, `alpine` does not contains bash.

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
brew install findutils
brew install gnu-tar
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

```bash
pushd .
cd makefile-common
git fetch -a && git checkout v0.10.0 && git pull
popd
```

Include in root Makefile in the next way:

```Makefile
include $(CURDIR)/makefile-common/include.mk.inc
```

**WARNING! If you use submodule and github actions, add to checkout action checkout submodules `submodules: "recursive"`, like:**
```yaml
...
    steps:
      - &checkout_step
        name: Checkout
        uses: actions/checkout@v6.0.2
        with:
          fetch-depth: 0
          submodules: "recursive"
          ref: ${{ github.event.pull_request.head.sha }}
...
```

## Update as submodule

```bash
cd makefile-common
git fetch -a && git checkout NEW_TAG && git pull
popd
```

## Post install/update

Please add to `.gitignore` all entries from this repository `.gitignore`.

and run `make common/git/check/gitignore GITIGNORES_WITH_REQUIRED_RULES=makefile-common/.gitignore`.

Because targets generate some files which do not commit to git repo.

## Pre-definitions

Includes contain some variables and make definitions.

## No print directories

Because includes uses recursive make calls 00-common.mk add `--no-print-directory` argument:

```Makefile
MAKEFLAGS += --no-print-directory
```

### Variables

Now includes files in `common` repo contains next predefined variables:
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
- `ARCH_CALCULATED` - result of command `uname -m` architecture (like `amd64`, `arm64`)
- `OS_CALCULATED` - OS name `linux` or `darwin` for MacOS
- `AWK_BIN` - awk binary name. For linux `awk`, for MacOS `gawk`
- `FIND_BIN` - `find` binary name. For linux `find`, for MacOS `gfind`
- `TAR_BIN` - tar binary name. For linux `tar`, for MacOS `gtar`
- `JQ_BIN_FULL` - full path to local installed [jq](https://github.com/jqlang/jq)
- `YQ_BIN_FULL` - full path to local installed [yq](https://github.com/mikefarah/yq)
- `BUILD_PATH` - directory to output builds (by default `$(CURDIR)/.build`). Can be redeclared with `SET_BUILD_PATH`
- `RELEASE_PATH` - directory to output release artifacts (by default `$(CURDIR)/.release`). Can be redeclared with `SET_RELEASE_PATH`

### Definitions

#### Callable

Next definitions can call in makefile with `$(shell $(call ...))` or `$(call ...)`:
- `CHECK_BINARY` - check that local binary installed and have target version.  
  Params:
  - `$(1)` - binary name in `BINARIES_PATH` dir.
  - `$(2)` - binary argument for consume current binary version.
  - `$(3)` - target binary version, that will grep from version call.

  When def called with shell, prepared script returns none-zero code
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
- `RUN_WITH_CLEANUP` - run target and call another targets after run first (with or without error).
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

This definitions can be used inside makefile targets as makefile variables, like:
```Makefile
do/some:
	@out="$$(${DEFINITION} "param1" "param2")"; \
	echo "$$out"
```

- `NOW_MICROSECONDS` - call date and return to stdout current unix-time with microseconds.
   No params. Usefully with `HUMAN_DURATION_MICROSECONDS`.
- `HUMAN_DURATION_MICROSECONDS` output duration microseconds in human way.
   Params:
   - `$1` - start microseconds unix-time (can get with `NOW_MICROSECONDS`)
   - `$2` - end microseconds unix-time (can get with `NOW_MICROSECONDS`)

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
- `RUN_WITH_DURATION` - call another target, calculate duration time and print duration.
  Warning! Because whe use call another bins in bash duration of target can little different 
  from run standalone.
  Params:
  - `$1` - makefile target
  - `$2` - human name of target for print.

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

  ${\color{green}Do \space with \space ok \space 02.023318s}$

    
  $ make test/run-with-duration/fail

  ${\color{red}Do \space with \space fail \space 02.023318s}$

#### Utils bash-functions includes

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
- `INCLUDE_SPLIT` - add next sh functions:
    - `trim_spaces_left` - trim whitespaces from left
      Arguments:
      - `$1` - string to trim
    - `trim_spaces_right` - trim whitespaces from right
      Arguments:
      - `$1` - string to trim
    - `trim_spaces` - trim whitespaces from right and left
      Arguments:
      - `$1` - string to trim
    - `split_by` - split string by separator to global array
      Arguments:
      - `$1` - separator (can be multi-character)
      - `$2` - name of destination array variable
      - `$3` - string to split
      - `$4` - function name to transform all values (like `trim_spaces`). got string argument and returns string. Optional
    - `split_by_comma` - split string by comma-separator to global array
      Arguments:
      - `$1` - name of destination array variable
      - `$2` - string to split
      - `$3` - function name to transform all values (like `trim_spaces`). got string argument and returns string. Optional
    - `split_by_space` - split string by space-separator to global array
      Arguments:
      - `$1` - name of destination array variable
      - `$2` - string to split
      - `$3` - function name to transform all values (like `trim_spaces`). got string argument and returns string. Optional
    - `split_by_new_line` - split string by new-line-separator to global array
      Arguments:
      - `$1` - name of destination array variable
      - `$2` - string to split
      - `$3` - function name to transform all values (like `trim_spaces`). got string argument and returns string. Optional

  Example:
  ```Makefile
  include *.mk
  test/trim:
  	@${INCLUDE_SPLIT} \
  	b="$$(trim_spaces $$'\n  \t\n\t   from begin')"; \
  	e="$$(trim_spaces $$'from end\n  \t\n\t  ')"; \
  	m="$$(trim_spaces $$'\n  \t\n\tin middle\n  \t\n\t  ')"; \
  	n="$$(trim_spaces "no trim")"; \
  	echo "'$$b'";\
  	echo "'$$e'";\
  	echo "'$$m'";\
  	echo "'$$n'"
  test/split:
  	@${INCLUDE_SPLIT} \
  	function print_arr() { \
  		local function_array=("$$@"); \
  		if [ "$${#function_array[@]}" -eq 0 ]; then \
  			echo "Got empty array"; \
  			return; \
  		fi; \
  		for item in "$${function_array[@]}"; do \
    			echo "Value: '$$item'"; \
    	done; \
  	}; \
  	function own_transform_fun() { \
  		echo -n "transformed: '$${1:-}'"; \
  	}; \
  	comma="a,b c,d"; \
  	split_by_comma "comma_arr" "$$comma"; \
  	echo "Comma-separated:"; \
  	print_arr "$${comma_arr[@]}"; \
  	new_line=$$'Hello with\n Name'; \
  	split_by_new_line "new_line_arr" "$$new_line"; \
  	echo "New line-separated:"; \
  	print_arr "$${new_line_arr[@]}"; \
  	spaces=$$'val ba bbval\nccc'; \
  	split_by_space "spaces_arr" "$$spaces"; \
  	echo "Spaces-separated:"; \
  	print_arr "$${spaces_arr[@]}"; \
  	own=$$'val ba. bbval\nccc'; \
  	split_by '.' "own_arr" "$$own"; \
  	echo "Dot-separated:"; \
  	print_arr "$${own_arr[@]}"; \
  	multi=$$'val ba\n b|||bval|||ccc'; \
  	split_by '|||' "multi_arr" "$$multi"; \
  	echo "Multi-separated:"; \
  	print_arr "$${multi_arr[@]}"
  	print_arr "$${multi_arr[@]}"; \
  	empty=""; \
  	split_by_comma "empty_arr" "$$empty"; \
  	echo "Empty:"; \
  	print_arr "$${empty_arr[@]}"; \
  	trim_left=$$'a, b b,,  c,\n d ,e f,'; \
  	split_by_comma "trim_left_arr" "$$trim_left" "trim_spaces_left"; \
  	echo "Transform trim left:"; \
  	print_arr "$${trim_left_arr[@]}"; \
  	trim_right=$$'a ,b b ,  c  ,d \n,e f'; \
  	split_by_comma "trim_right_arr" "$$trim_right" "trim_spaces_right"; \
  	echo "Transform trim right:"; \
  	print_arr "$${trim_right_arr[@]}"; \
  	trim_all=$$' a , b b ,  c,\n d \n,e f,g '; \
  	split_by_comma "trim_all_arr" "$$trim_all" "trim_spaces"; \
  	echo "Transform trim all:"; \
  	print_arr "$${trim_all_arr[@]}"; \
  	trim_all_empty=""; \
  	split_by_comma "trim_all_empty_arr" "$$trim_all_empty" "trim_spaces"; \
  	echo "Transform trim all empty:"; \
  	print_arr "$${trim_all_empty_arr[@]}"; \
  	transform_own="a||b c|| de||g"; \
  	split_by "||" "transform_own_arr" "$$transform_own" "own_transform_fun"; \
  	echo "Transform own:"; \
  	print_arr "$${transform_own_arr[@]}"
  ```
- `INCLUDE_CHECK_BINARY` - add next sh function (`INCLUDE_ECHO` also included):
    - `check_binary` - check that binary is exists in `BINARIES_PATH` and executable and have correct version.
        Arguments:
        - `$1` - binary name without path
        - `$2` - version argument for binary for extract version
        - `$3` - version to check. Function uses grep for match version

        If binary present and executable and have correct version returns zero code, otherwise - 1, invalid args - 2
    - `check_and_download_bin` - check that binary is exists in `BINARIES_PATH` and executable and have correct version
                                 if not - download.
        Arguments:
        - `$1` - url to download. Can be contains next string for substitution
          - `@BIN_VER@ ` - replace to version passed via `$3`
          - `@BIN_OS@`   - replace to calculated os name `$(OS_CALCULATED)` (linux or darwin) 
          - `@BIN_ARCH@` - replace to calculated os name `$(ARCH_CALCULATED)` (amd64 or arm64) 
        - `$2` - binary name without path (can be passed with env `INSTALL_BIN_NAME`)
        - `$3` - version argument passed in binary for extract version (can be passed with env `INSTALL_BIN_VERSION_ARG`)
        - `$4` - version to check. Function uses grep for match version (can be passed with env `INSTALL_BIN_VERSION`)

        If binary present and executable and have correct version returns zero code, otherwise - 1, invalid args - 2
    - `check_and_get_bin` - check that binary is exists in `BINARIES_PATH` and executable and have correct version
                            if not - call passed function for get binary.
        Arguments:
        - `$1` - function name for get binary. Function pass next args to get function
          - `$1` - version of binary
          - `$2` - arch (amd64 or arm64)
          - `$3` - os (linux or darwin) 
          - `$4` - binary name only 
          - `$5` - full binary path
          - `$6` - binaries path $(BINARIES_PATH) 
        - `$2` - binary name without path (can be passed with env `INSTALL_BIN_NAME`)
        - `$3` - version argument passed in binary for extract version (can be passed with env `INSTALL_BIN_VERSION_ARG`)
        - `$4` - version to check. Function uses grep for match version (can be passed with env `INSTALL_BIN_VERSION`)

        If binary present and executable and have correct version returns zero code, otherwise - 1, invalid args - 2

  Example:
  ```Makefile
  include *.mk

  DUMMY_BIN = dummy
  DUMMY_FULL_BIN = $(BINARIES_PATH)/$(DUMMY_BIN)

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
  _test/install/dummy: export INSTALL_BIN_NAME = $(DUMMY_BIN)
  _test/install/dummy: export INSTALL_BIN_VERSION_ARG = ver
  _test/install/dummy: export INSTALL_BIN_VERSION = 0.0.1
  _test/install/dummy:
  	@function get_dummy() { \
  		local ver="$$1"; \
  		local arch="$$2"; \
  		local os="$$3"; \
  		local name="$$4"; \
  		local dest="$$5"; \
  		local pt="$$6"; \
  		{ \
  			echo -n "#"; \
  			echo '!/usr/bin/env bash'; \
  			echo 'if [[ $$1 == "ver" ]]; then'; \
  			echo -n '  echo "'; \
  			echo -n "name=$$name; path=$$pt; arch=$$arch; os=$$os; v$$ver"; \
  			echo '"'; \
  			echo 'fi'; \
  		} > "$$dest"; \
  	}; \
  	${INCLUDE_CHECK_BINARY} \
  	if ! check_and_get_bin get_dummy; then \
  		exit 1; \
  	fi; \
  	if [ ! -x "$(DUMMY_FULL_BIN)" ]; then \
  		exit_with_err "$(DUMMY_FULL_BIN) is not executable"; \
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
             Should be `amd64` or `arm64`.

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
- `INCLUDE_BIN_DYNAMIC` - add next sh function:
   - `check_dynamic_executable` - check that binary is dynamic linked or not
      Arguments:
      - `$1` - binary path. Required. Also can be passed via env `TARGET_BIN_TO_CHECK`
      - `$2` - if not empty check that executable is dynamic-linked, otherwise that static linked
              Also can be passed via env `TARGET_BIN_SHOULD_DYNAMIC`
              Optional.

      If have argument errors - returns 2, returns 1 if executable not/is dynamic-linked depended on `$2`
      If executable linked correct returns 0.

  Example:
  ```Makefile
  include *.mk

  check/dynamic: export TARGET_BIN_TO_CHECK = $(BUILD_PATH)/app-dynamic
  check/dynamic: export TARGET_BIN_SHOULD_DYNAMIC = true
  check/dynamic:
  	@${INCLUDE_BIN_DYNAMIC} \
  	if ! check_dynamic_executable; then \
  		exit 1; \
  	fi

  check/static: export TARGET_BIN_TO_CHECK = $(BUILD_PATH)/app-static
  check/static:
  	@${INCLUDE_BIN_DYNAMIC} \
  	if ! check_dynamic_executable; then \
  		exit 1; \
  	fi
  ```
## Targets

### Help

- `help` - print help for all marked targets in root Makefile and all includes. Set as default target.
  See instruction for add help and examples [below](#add-targets-to-help-output)

### Third-party binaries

- `bin` - create `BINARIES_PATH`
- `install/binary` - check that binary is exists in `BINARIES_PATH` and executable and have correct version, if not - download.
  **WARNING! Call this target with recursive call make to prevent skip run target in another targets multiple times!**

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
- `check/installed/bin` - check that binary installed in system.
   **WARNING! Call this target with recursive call make to prevent skip run target in another targets multiple times!**

   Params:
   - `BIN_NAME`=*NAME* - name of binary for check

   Example:
   ```Makefile
   check/installed/curl: export BIN_NAME = curl
   check/installed/curl:
	 	@$(MAKE) check/installed/bin # USE MAKE FOR PREVENT SKIP TARGET!
   ```
- `check/installed/tar` - check that GNU `tar` (for MacOS `gtar`) is installed in the system
- `check/installed/find` - check that GNU `find` (for MacOS `gfind`) is installed in the system
- `check/installed/sha256sum` - check that `sha256sum` is installed in the system
- `check/installed/curl` - check that [curl](https://curl.se/) is installed in the system
- `check/installed/docker` - check that [docker](https://www.docker.com/) is installed in the system
- `install/jq` - install [jq](https://github.com/jqlang/jq) to local bin path
- `install/yq` - install [yq](https://github.com/mikefarah/yq) to local bin path
- `clean/common` - remove binaries installed with common package (`yq` and `jq` now)
- `check/bin/linked/dynamic` - check that executable is dynamic-linked

   Params:
   - `TARGET_BIN_TO_CHECK`=*PATH* - path to executable to check

   Example:
    ```Makefile
    check/dynamic: export TARGET_BIN_TO_CHECK = $(BUILD_PATH)/app-dynamic
    check/dynamic: check/bin/linked/dynamic
    ```
- `check/bin/linked/static` - heck that executable is static-linked

   Params:
   - `TARGET_BIN_TO_CHECK`=*PATH* - path to executable to check

   Example:
    ```Makefile
    check/static: export TARGET_BIN_TO_CHECK = $(BUILD_PATH)/app-static
    check/static: check/bin/linked/static
    ```

### Build

Next targets are generic targets for build binaries. Before run creates `BUILD_PATH` dir.
Every target take next params:
- `PROJECT_NAME` - name of project
- `BUILD_TARGET` - make target for run.

Targets pass to `BUILD_TARGET` next params:
- `OUT_BIN`    - output binary file path in `./.build` (can be redeclared with `SET_BUILD_PATH`). 
                 File has next format `$(BUILD_PATH)/$(PROJECT_NAME)-OS-ARCH`
- `BUILD_OS`   - os for build (linux or darwin)
- `BUILD_ARCH` - build arch (amd64 or arm64).

Targets:
- `common/build/dir`       - creates `BUILD_PATH` dir
- `common/build/current`   - build binary for current machine os and arch
- `common/build/linux`     - build binary for current machine arch linux
- `common/build/linux/all` - build binary for linux and all supported arch'es
- `common/build/mac`       - build binary for MacOS and arm64 arch
- `common/build/mac/all`   - build binary for MacOS and all supported arch'es
- `common/build/all`       - build binary for all supported os'es and arch'es
- `clean/build`            - remove `BUILD_PATH` dir.

### Release artifacts

Next target prepare release artifact with calculate sha256 sum.

All next targets uses `RELEASE_PATH` root dir to output artifacts.
By default `$(CURDIR)/.release`, can be redeclared with `SET_RELEASE_PATH` parameter.

Targets:
- `common/release/dir` - create root dir for output artifacts

  Params:
  - `RELEASE_NAME` - name of release (for example, tag). Required.
     Should **not** contains `/` symbol, because this name uses as sub-dir in `RELEASE_PATH`.

- `clean/release` - Delete release directory `RELEASE_PATH`

- `common/release` - prepare release artifacts for upload. See description after describe parameters.
  **WARNING!** Target will not cleanup any files if fail! 

  Params:
  - `PROJECT_NAME`=*NAME* - name of project. Required
  - `RELEASE_NAME`=*NAME* - name of release (for example, tag). Required
     Should not contains `/` symbol, because this name uses as sub-dir in `RELEASE_PATH`.
  - `BINARIES_DIR`=*PATH* - dir with target files or directories. 
	  Optional. By default uses `BUILD_PATH`
  - `ADDITIONAL_ARTIFACTS_DIR`=*PATH* -  if passed all files in this dir
	  will add to release archive for all targets. 
	  Helpful to add install script, systemd service, readme/license files
	  Optional.
	  If passed, but dir not found or not contains any files - fail with error.

  `common/release` target do next operations:
	- create `$(RELEASE_PATH)/$(RELEASE_NAME)` directory.
	
  - find all executable files with `PROJECT_NAME` prefix in `BINARIES_DIR`. 
	  If found one or more executable files:
	  - if `ADDITIONAL_ARTIFACTS_DIR` not empty, for each executable:
        - creates temp directory in `$(RELEASE_PATH)/$(RELEASE_NAME)` with name of executable
        - copy executable (with name `PROJECT_NAME`, **without suffix!**).
        - copy all files from `ADDITIONAL_ARTIFACTS_DIR`
        - chmod to `755` executable
        - creates `{executable name}.tar.gz` archive from temp dir
        - calculate sha256sum from archive and write hash to `{executable name}.tar.gz.sha256sum` file.
        - remove temp dir.
	  - if `ADDITIONAL_ARTIFACTS_DIR` empty:
	    - copy each executable as is (with `PROJECT_NAME` and suffix) to `$(RELEASE_PATH)/$(RELEASE_NAME)`
	    - chmod to `755` executable
	    - calculate sha256sum from executable and write hash to `{executable name}.sha256sum` file.
	  - End of script.
	- If executables not found, find directories with `PROJECT_NAME` prefix in `BINARIES_DIR`.
    This case helpful if you release consists of multiple files, like python project.
	  - If found, for each directory: 
	    - creates temp directory in `$(RELEASE_PATH)/$(RELEASE_NAME)` with name of dir (with `PROJECT_NAME` and suffix)
	    - copy all from directory to temp dir
	    - copy all from `ADDITIONAL_ARTIFACTS_DIR` if it is not empty
	    - creates `{dir name}.tar.gz` archive from temp dir
	    - calculate sha256sum from archive and write hash to `{dir name}.tar.gz.sha256sum` file
	    - remove temp dir.
	 
	- If not found any executable files or directories - fail with error.

  After all you can upload `$(RELEASE_PATH)/$(RELEASE_NAME)` to artifacts of release in `Github` or `Gitlab`.
  
  Output examples: 
  - only binary release without artifacts. 
    
    If you pass:
    - `PROJECT_NAME=app`
    - `RELEASE_NAME=v1.0.0`

    And you `.build/` directory contains next binaries:
    - `app-linux-amd64`
    - `app-linux-arm64`
    
    You will get next files in `.release/v1.0.0`:
    - `app-linux-amd64`
    - `app-linux-amd64.sha256sum`
    - `app-linux-arm64`
    - `app-linux-arm64.sha256sum`
    
  - only binary release with artifacts. 
    
    If you pass:
    - `PROJECT_NAME=app`
    - `RELEASE_NAME=v1.0.0`
    - `ADDITIONAL_ARTIFACTS_DIR=.build/.artifacts`

    You `.build/` directory contains next binaries:
    - `app-linux-amd64`
    - `app-linux-arm64`

    And you `.build/.artifacts` directory contains next files:
    - `README.md`
    - `LICENSE`
    
    You will get next files in `.release/v1.0.0`:
    - `app-linux-amd64.tar.gz`
    - `app-linux-amd64.tar.gz.sha256sum`
    - `app-linux-arm64.tar.gz`
    - `app-linux-arm64.tar.gz.sha256sum`

    `app-linux-amd64.tar.gz` will contains:
    - `/app`
    - `/README.md`
    - `/LICENSE`

### Git

- `common/git/check/gitignore` - check that gitignore file contains another gitignore files rules.
   Usefully for checking in another includes repos and root makefile that all gitignore rules
   were added to root `.gitignore` file.
   
   Params:
   - `ROOT_GITIGNORE`=*PATH* - path to gitignore file for check (root .gitignore). Default `$(CURDIR)/.gitignore`
   - `GITIGNORES_WITH_REQUIRED_RULES`=*PATHS...* - comma separated paths to gitignore files that should contains `ROOT_GITIGNORE`.

- `common/git/check/has-diff` - check that repo has difference
  
  Params:
  - `TARGET_NAME`=*NAME* - if passed run make target before git check. Optional
  - `HAS_DIFF_MSG`=*MSG* - if has diff this message will be printed. Optional. If not passed print files.
  - `FILES_TO_CHECK`=*REGEXPS...* - comma separated paths regexp for check. Optional
  - `FILES_TO_SKIP`=*REGEXPS...*  - comma separated paths regexp for skip. Optional. Has higher priority.
  
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
  ${\color{yellow}target}$&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;  Check that gitignore file contains another gitignore files rules.<br>
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
