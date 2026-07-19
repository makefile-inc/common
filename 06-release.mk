ifndef SET_RELEASE_PATH
  SET_RELEASE_PATH = $(CURDIR)/.release
endif

RELEASE_PATH = $(abspath $(SET_RELEASE_PATH))

##@ Common. Release artifacts

common/release/dir: ## Make release dir
	@##~ RELEASE_NAME=NAME - name of release (tag). Required.
	@##~   Should not contains / symbol.
	@##~ SET_RELEASE_PATH=PATH - dir for output release artifacts. By default $(CURDIR)/.release
	@${INCLUDE_ECHO} \
	if [ -z "$$RELEASE_NAME" ]; then \
		exit_with_err "RELEASE_NAME is not passed"; \
	fi; \
	if [[ "$$RELEASE_NAME" == */* ]]; then \
		exit_with_err "RELEASE_NAME '$$RELEASE_NAME' contains '/' symbol"; \
	fi; \
	mkdir -p "$(RELEASE_PATH)/$$RELEASE_NAME"

common/release: check/installed/tar check/installed/sha256sum check/installed/find common/release/dir ## Prepare release artifacts. If failed - not cleanup!
	@##~ PROJECT_NAME=NAME - name of project. Required
	@##~ RELEASE_NAME=NAME - name of release (tag). Required.
	@##~   Should not contains / symbol.
	@##~ ADDITIONAL_ARTIFACTS_DIR=PATH -  if passed all files in this dir
	@##~   will add to release archive for all targets. 
	@##~   Helpful to add install script, systemd service, readme/license files
	@##~   Optional.
	@##~   If passed, but dir not found or not contains any files - fail with error.
	@##~ BINARIES_DIR=PATH - dir with target file or dir. 
	@##~   Optional. By default uses $(BUILD_PATH)
	@##~   Target has next rules:
	@##~   First, create $(RELEASE_PATH)/$(RELEASE_NAME) directory
	@##~   Second, find all executables with $(PROJECT_NAME) prefix. 
	@##~   If found:
	@##~    if ADDITIONAL_ARTIFACTS_DIR not empty
	@##~     for each executable creates temp directory in $(RELEASE_PATH)/$(RELEASE_NAME) with name of executable
	@##~     copy executable (with name without suffix), copy all files from ADDITIONAL_ARTIFACTS_DIR
	@##~     chmod to 755 executable
	@##~     creates {executable name}.tar.gz archive from temp dir
	@##~     calculate sha256sum from archive and write hash to {executable name}.tar.gz.sha256sum file.
	@##~     remove temp dir.
	@##~    if ADDITIONAL_ARTIFACTS_DIR empty
	@##~     copy each executable as is $(RELEASE_PATH)/$(RELEASE_NAME)
	@##~     chmod to 755 executable
	@##~     calculate sha256sum from executable and write hash to {executable name}.sha256sum file.
	@##~    End of script
	@##~   If executables not found, find directories with $(PROJECT_NAME) prefix. 
	@##~    If found: 
	@##~     for each directory creates temp directory in $(RELEASE_PATH)/$(RELEASE_NAME) with name of dir
	@##~     copy all from directory to temp dir
	@##~     copy all from ADDITIONAL_ARTIFACTS_DIR if it is not empty
	@##~     creates {dir name}.tar.gz archive from temp dir
	@##~     calculate sha256sum from archive and write hash to {dir name}.tar.gz.sha256sum file
	@##~     remove temp dir.
	@##~    Case with directories helpful if you release consists of multiple files.
	@##~   If not found any executables or dirs - fail with error.
	@##~   After all you can upload $(RELEASE_PATH)/$(RELEASE_NAME) to artifacts of release in Github or Gitlab.
	@${INCLUDE_ECHO} \
	if [ -z "$$PROJECT_NAME" ]; then \
		exit_with_err "PROJECT_NAME is not passed"; \
	fi; \
	artifacts_dir=""; \
	if [ -n "$$ADDITIONAL_ARTIFACTS_DIR" ]; then \
		if ! artifacts_dir="$$(realpath "$$ADDITIONAL_ARTIFACTS_DIR")"; then \
			exit_with_err "Cannot real path of '$$ADDITIONAL_ARTIFACTS_DIR'"; \
		fi; \
		if [ ! -d "$$artifacts_dir" ]; then \
			exit_with_err "'$$artifacts_dir' is not dir"; \
		fi; \
		count_in_artifacts=0; \
		count_in_artifacts="$$($(FIND_BIN) "$$artifacts_dir" -type f | wc -l)"; \
		if [ "$$count_in_artifacts" -eq 0 ]; then \
			exit_with_err "'$$artifacts_dir' does not contains any file"; \
		fi; \
		count_non_regulars_in_artifacts=1; \
		count_non_regulars_in_artifacts="$$($(FIND_BIN) "$$artifacts_dir" ! -type d ! -type f -not -path "$$artifacts_dir" | wc -l)"; \
		if [[ "$$count_non_regulars_in_artifacts" != "0" ]]; then \
			echo_err "None regulars files in '$$artifacts_dir':"; \
			$(FIND_BIN) "$$artifacts_dir" ! -type d ! -type f -not -path "$$artifacts_dir"; \
			exit_with_err "'$$artifacts_dir' contains none regular files"; \
		fi; \
	fi; \
	dest_dir="$(RELEASE_PATH)/$$RELEASE_NAME"; \
	if [ ! -d "$$dest_dir" ]; then \
		exit_with_err "'$$dest_dir' destination release dir not found. Please run make common/release/dir"; \
	fi; \
	bin_dir="$$BINARIES_DIR"; \
	if [ -z "$$bin_dir" ]; then \
		bin_dir="$(BUILD_PATH)"; \
		echo_info "BINARIES_DIR not passed. Use $$bin_dir"; \
	fi; \
	if ! bin_dir="$$(realpath "$$bin_dir")"; then \
		exit_with_err "'$$bin_dir' cannot get real path"; \
	fi; \
	if [ ! -d "$$bin_dir" ]; then \
		exit_with_err "'$$bin_dir' is not directory"; \
	fi; \
	function prepare_artifact() { \
		local exec_f="$$1"; \
		local exec_base=""; \
		if ! exec_base="$$(basename "$$exec_f")"; then \
			exit_with_err "Cannot extract basename from '$$exec_f'"; \
		fi; \
		local full_dest_artifact="$${dest_dir}/$${exec_base}"; \
		if [ -n "$$artifacts_dir" ]; then \
			if ! mkdir -p "$$full_dest_artifact"; then \
				exit_with_err "Cannot create artifacts temp dir for '$$full_dest_artifact'"; \
			fi; \
			if ! cp -aR "$${artifacts_dir}/." "$$full_dest_artifact"; then \
				exit_with_err "Cannot copy artifacts from '$${artifacts_dir}' to release dir '$$full_dest_artifact'"; \
			fi; \
		fi; \
		local target_artifact="$$full_dest_artifact"; \
		if [ -d "$$exec_f" ]; then \
			if ! mkdir -p "$$full_dest_artifact"; then \
				exit_with_err "Cannot create artifacts temp dir for '$$full_dest_artifact'"; \
			fi; \
			if ! cp -aR "$${exec_f}/." "$$full_dest_artifact"; then \
				exit_with_err "Cannot copy '$$exec_f' dir to '$$full_dest_artifact'"; \
			fi; \
		elif [ -f "$$exec_f" ]; then \
			if [ -d "$$full_dest_artifact" ]; then \
				local dest_artifact_name="${exec_base%%"$$PROJECT_NAME"*}$$PROJECT_NAME"; \
				full_dest_artifact="$${full_dest_artifact}/$${dest_artifact_name}"; \
			fi; \
			if ! cp "$$exec_f" "$$full_dest_artifact"; then \
				exit_with_err "Cannot copy binary '$$exec_f' to '$$full_dest_artifact'"; \
			fi; \
			if ! chmod 755 "$$full_dest_artifact"; then \
				exit_with_err "Cannot chmod 755 on '$$full_dest_artifact'"; \
			fi; \
		else \
			exit_with_err "'$$exec_f' is not file or dir or not exist"; \
		fi; \
		local file_for_sum="$$target_artifact"; \
		if [ -d "$$target_artifact" ]; then \
			file_for_sum="$${file_for_sum}.tar.gz"; \
			echo_info "Artifact '$$target_artifact' is dir. Compress to '$$file_for_sum'"; \
			$(FIND_BIN) "$$target_artifact" \( -type f -o -type d \) -printf "%P\n" | $(TAR_BIN) -czf "$$file_for_sum" --no-recursion -C "$$target_artifact" -T - >&2; \
			local tar_statuses=("$${PIPESTATUS[@]}"); \
			if [[ "$${tar_statuses[0]}" != "0" || "$${tar_statuses[1]}" != "0" ]]; then \
				exit_with_err "Cannot compress '$$target_artifact' to '$$file_for_sum'"; \
			fi; \
			echo_info "Remove temp directory '$$target_artifact' for '$$exec_f':"; \
			if ! rm -rfv "$$target_artifact" >&2; then \
				exit_with_err "Cannot remove temp dir '$$target_artifact'"; \
			fi; \
		fi; \
		echo -n "$$file_for_sum"; \
	}; \
	function finalize_release_exec() { \
		local exec_fl="$${1}"; \
		local for_calculate="$${2}"; \
		local sum_file="$${for_calculate}.sha256sum"; \
		local dir_name=""; \
		if ! dir_name="$$(dirname "$$for_calculate")"; then \
			exit_with_err "Cannot get dir for '$$for_calculate'"; \
		fi; \
		local base_name=""; \
		if ! base_name="$$(basename "$$for_calculate")"; then \
			exit_with_err "Cannot get basename for '$$for_calculate'"; \
		fi; \
		pushd . > /dev/null; \
		cd "$$dir_name"; \
		if ! sha256sum -b "$$base_name" > "$$sum_file"; then \
			exit_with_err "Cannot calculate sha256 artifacts '$$for_calculate' ('$$base_name') for '$$exec_fl'"; \
		fi; \
		popd > /dev/null; \
		local sha_sum=""; \
		if ! sha_sum="$$(cut -d' ' -f1 "$$sum_file")"; then \
			exit_with_err "SHA file '$$sum_file' content does not get"; \
		fi; \
		if [ -z "$$sha_sum" ]; then \
			exit_with_err "sha sum is empty"; \
		fi; \
		echo_info "Release artifacts for '$$exec_fl' created:"; \
		echo_info "  Artifact: $$for_calculate"; \
		echo_info "  Sum file: $$sum_file"; \
		echo_info "  SHA256: $$sha_sum"; \
	}; \
	found_exec=""; \
	while IFS= read -r -d '' exec_file; do \
		found_exec="true"; \
		echo_info "Found executable $$exec_file"; \
		artifact_name=""; \
		if ! artifact_name="$$(prepare_artifact "$$exec_file")"; then \
			exit_with_err "Cannot prepare artifact for $$exec_file"; \
		fi; \
		finalize_release_exec "$$exec_file" "$$artifact_name"; \
	done < <($(FIND_BIN) "$$bin_dir" -maxdepth 1 -type f -executable -name "$${PROJECT_NAME}*" -print0); \
	if [ -z "$$found_exec" ]; then \
		while IFS= read -r -d '' exec_dir; do \
			found_exec="true"; \
			echo_info "Found executable $$exec_dir"; \
			artifact_dir_name=""; \
			if ! artifact_dir_name="$$(prepare_artifact "$$exec_dir")"; then \
				exit_with_err "Cannot prepare artifact for $$exec_dir"; \
			fi; \
			finalize_release_exec "$$exec_dir" "$$artifact_dir_name"; \
		done < <($(FIND_BIN) "$$bin_dir" -maxdepth 1 -type d -name "$${PROJECT_NAME}*" -print0); \
	fi; \
	if [ -z "$$found_exec" ]; then \
		exit_with_err "Cannot found any executable file or directory for project '$$PROJECT_NAME'"; \
	fi; \
	echo_info "All artifacts for project '$$PROJECT_NAME' were prepared to '$$dest_dir'"; \
	echo_info "List artifacts:"; \
	for artf_f in $$(ls "$$dest_dir"); do \
		echo_info "  $$artf_f"; \
	done

clean/release: ## Delete release directory 
	@rm -rfv "$(RELEASE_PATH)"

.PHONY: common/release/dir common/release clean/release

