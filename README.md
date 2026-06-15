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

Checkout to target wersion:

```
pushd .
cd makefile-common
git fetch -a && git checkout v0.1.0 && git pull
popd
```

Include in root Makefile in the next way:

```Makefile
include $(CURDIR)/makefile-common/include.mk.inc
```

## Pre-definitions

Includes contain some variables and make definitions. 

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
- `PLATFORM_NAME` - result of command `uname -m` (like `x86_64`, `arm64`)
- `OS_NAME` - OS name `Linux` or `Darwin` for MacOS
- `AWK_BIN` - awk binary name. For linux `awk`, for MacOS `gawk`
- `JQ_BIN_FULL` - full path to local installed [jq](https://github.com/jqlang/jq)
- `YQ_BIN_FULL` - full path to local installed [yq](https://github.com/mikefarah/yq)

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
  

## Targets

- `bin` - create `BINARIES_PATH`
- `check/installed/curl` - check that [curl](https://curl.se/) is installed in the system
- `check/installed/docker` - check that [docker](https://www.docker.com/) is installed in the system
- `install/jq` - install [jq](https://github.com/jqlang/jq) to local bin path
- `install/yq` - install [yq](https://github.com/mikefarah/yq) to local bin path
- `clean/common` - remove binaries installed with common package (`yq` and `jq` now)
- `check/common/gitignore` - check that gitignore file contains another gitignore files rules.
   Userfull for checking in another includes repos and rott makefile that all gitignore rules
   were added to root `.gitignore` file.
   Params:
   - `ROOT_GITIGNORE`=*PATH* - path to gitignore file for check (root .gitignore). Default `$(CURDIR)/.gitignore`
   - `GITIGNORES_WITH_REQUIRED_RULES`=*PATHS...* - comma separated paths to gitignore files that should contains `ROOT_GITIGNORE`.
- `help` - print help for all marked targets in root Makefile and all includes. Set as default target.
  See instruction for add help and examples [below](#add-targets-to-help-output)

### Add targets to help output

#### Example output:

Usage: make ${\color{yellow}target}$ OPTION=${\color{cyan}value}$

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

After definition and description add `##~ ` &nbsp; and parameter description after `##~ `.
For multiple params, add multiple `##~ ` &nbsp; for every param separated by new line.
Example:

```Makefile
target: ## Target description
	##~ OP_NAME=name - operation name
	##~ HELLO_NAME=name - name for output hello
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
