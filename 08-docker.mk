# Copyright 2026
# license that can be found in the LICENSE file.

__DEFAULT_COMPOSE_FILE = $(CURDIR)/docker-compose.yaml

##@ Common. Docker and docker compose

# INCLUDE_DOCKER_UTILS - add next sh functions:
#   docker_slugify_tag - prepare string for using as docker tag  
#     Arguments:
#       $1 - string for slugify
# 	get_compose_file - get docker compose file from env COMPOSE_FILE or $(CURDIR)/docker-compose.yaml
#	  Arguments: do not take any arguments
#	check_compose_params - prepare general args for run docker compose
# 	    Get docker compose file with get_compose_file and check it exist.
# 	    If passed COMPOSE_ENV env, check that file is exist and add --env-file arg
# 	    If COMPOSE_ENV not exists, print that file is not exist and
# 	    if passed COMPOSE_ENV_EXAMPLE env, print usage this example file for create COMPOSE_ENV file
#     Arguments:
#       $1 - array name for set args
#	run_compose - run docker compose and returns docker compose exit code.
#     Arguments:
#       $1 - array name for set args, which passed to check_compose_params
#       Another arguments passed to docker compose after general params
#   get_containers_with_labels_obj - returns json array with docker containers but Labels is object
#	  Arguments: do not take any arguments
#   get_containers_by_label - returns json array (returned from get_containers_with_labels_obj) with docker containers filtered by label
#     Arguments:
#       $1 - label key
#       $2 - label val
#   get_docker_compose_containers - returns json array (returned from get_containers_with_labels_obj) for docker compose file
#     Arguments:
#       $1 - compose file path
#   has_not_docker_compose_containers - returns 0 if docker compose file has not containers
#     Arguments:
#       $1 - compose file path
# Example include:
#   @${INCLUDE_DOCKER_UTILS} \ - slash is required!
# Can be included multiple times because sh redeclare function without error
define INCLUDE_DOCKER_UTILS
${INCLUDE_ECHO} \
function docker_slugify_tag() { \
	local input="$$1"; \
	local slug="$${input,,}"; \
	slug="$${slug//[^a-z0-9.-]/-}"; \
	while [[ "$$slug" == *--* ]]; do \
		slug="$${slug//--/-}"; \
	done; \
	while [[ "$$slug" == .* || "$$slug" == -* ]]; do \
		slug="$${slug:1}"; \
	done; \
	slug="$${slug%-}"; \
	echo -n "$${slug:0:128}"; \
}; \
function get_compose_file() { \
	local compose_file="$${COMPOSE_FILE:-}"; \
	if [ -z "$$compose_file" ]; then \
		compose_file="$(__DEFAULT_COMPOSE_FILE)"; \
	fi; \
	echo -n "$$compose_file"; \
}; \
function check_compose_params() { \
	local run_array_name="$$1"; \
	if [ -z "$$run_array_name" ]; then \
		exit_with_err "run array dest name not passed as first argument"; \
	fi; \
	local compose_file="$$(get_compose_file)"; \
	if [ ! -f "$$compose_file" ]; then \
		exit_with_err "COMPOSE_FILE '$$compose_file' param for run docker compose is not file"; \
	fi; \
	local args_for_pass=( \
		"-f" \
		"$$compose_file" \
	); \
	if [ -n "$${COMPOSE_ENV:-}" ]; then \
		local env_file="$$COMPOSE_ENV"; \
		example_file="$(CURDIR)/example.env"; \
		if [ ! -f "$$env_file" ]; then \
			echo_err "Configuration env file '$$env_file' not found"; \
			if [ -n "$${COMPOSE_ENV_EXAMPLE}" ]; then \
				echo_err "Please copy '$$COMPOSE_ENV_EXAMPLE' to '$$env_file' and configure compose"; \
			fi; \
			exit 1; \
		fi; \
		args_for_pass+=("--env-file"); \
		args_for_pass+=("$$env_file"); \
	fi; \
	local -n __compose_dest_args="$$run_array_name"; \
	for indx in "$${!args_for_pass[@]}"; do \
		__compose_dest_args["$$indx"]="$${args_for_pass[$$indx]}"; \
	done; \
}; \
function run_compose() { \
	local args_arr_name="$$1"; \
	if [ -z "$$args_arr_name" ]; then \
		exit_with_err "docker compose args array name not passed as first argument"; \
	fi; \
	shift; \
	local -n __compose_run_args="$$args_arr_name"; \
	docker compose "$${__compose_run_args[@]}" "$$@"; \
	return $$?; \
}; \
function get_containers_with_labels_obj() { \
	local jq_bin="$(JQ_BIN_FULL)"; \
	if [ ! -x "$$jq_bin" ]; then \
		echo_error "jq is not installed"; \
		return 1; \
	fi; \
	local ps_out=""; \
	if ! ps_out="$$(docker ps --format json)"; then \
		echo_error "Cannot run docker ps"; \
		return 1; \
	fi; \
	echo "$$ps_out" | "$$jq_bin" -s 'map({ \
		Names: .Names, \
		ID: .ID, \
		CreatedAt: .CreatedAt, \
		State: .State, \
		HealthStatus: .HealthStatus, \
		Image: .Image, \
		Labels: ( \
			(.Labels // "") \
			| split(",") \
			| map( \
        		select(. != "") \
        		| split("=") \
        		| {(.[0]): (.[1:] | join("="))} \
      		) \
    		| add // {} \
		) \
	})'; \
	return $$?; \
}; \
function get_containers_by_label() { \
	local l_key="$$1"; \
	local l_val="$${2:-}"; \
	local jq_bin="$(JQ_BIN_FULL)"; \
	if [ ! -x "$$jq_bin" ]; then \
		echo_error "jq is not installed"; \
		return 1; \
	fi; \
	if [ -z "$$l_key" ]; then \
		echo_error "key not passed to get_containers_by_label"; \
		return 1; \
	fi; \
	local containers_out=""; \
	if ! containers_out="$$(get_containers_with_labels_obj)"; then \
		echo_error "cannot extract containers"; \
		return 1; \
	fi; \
	echo "$$containers_out" | "$$jq_bin" --arg lk "$$l_key" --arg lv "$$l_val" 'map(select(.Labels[$$lk] == $$lv))'; \
	return $$?; \
}; \
function get_docker_compose_containers() { \
	local compose_file="$$1"; \
	local jq_bin="$(JQ_BIN_FULL)"; \
	if [ ! -x "$$jq_bin" ]; then \
		echo_error "jq is not installed"; \
		return 1; \
	fi; \
	if [ -z "$$compose_file" ]; then \
		echo_error "compose file not passed to get_docker_compose_containers"; \
		return 1; \
	fi; \
	local containers_out=""; \
	if ! containers_out="$$(get_containers_by_label "com.docker.compose.project.config_files" "$$compose_file")"; then \
		echo_error "cannot extract containers for docker compose '$$compose_file'"; \
		return 1;\
	fi; \
	echo "$$containers_out"; \
	return 0; \
}; \
function has_not_docker_compose_containers() { \
	local compose_file="$$1"; \
	local jq_bin="$(JQ_BIN_FULL)"; \
	if [ ! -x "$$jq_bin" ]; then \
		echo_error "jq is not installed"; \
		return 1; \
	fi; \
	if [ -z "$$compose_file" ]; then \
		echo_error "compose file not passed to get_docker_compose_containers"; \
		return 1; \
	fi; \
	local containers_out=""; \
	if ! containers_out="$$(get_docker_compose_containers "$$compose_file")"; then \
		echo_error "cannot extract containers for docker compose '$$compose_file'"; \
		return 1;\
	fi; \
	local c_len="0"; \
	if ! c_len="$$(echo "$$containers_out" | "$$jq_bin" 'length')"; then \
		echo_error "cannot get len of containers for docker compose '$$compose_file'"; \
		return 1; \
	fi; \
	if [[ "$$c_len" == "0" ]]; then \
		return 0; \
	fi; \
	echo_error "Found $$c_len containers for docker compose '$$compose_file':"; \
	if ! echo "$$containers_out" | "$$jq_bin" -r '.[].Names' >&2; then \
		true; \
	fi; \
	return 1; \
};
endef

check/installed/docker: export BIN_NAME = docker
check/installed/docker: ## Check docker is installed
	@$(MAKE) check/installed/bin

check/installed/docker/compose: check/installed/docker ## Check docker compose plugin is installed
	@${INCLUDE_ECHO} \
	if ! docker compose --help > /dev/null 2>&1; then \
		exit_with_err "docker compose plugin is not installed"; \
	fi

docker/compose/run: check/installed/docker/compose ## down and up docker compose
	@##~ COMPOSE_FILE=PATH           - docker compose file
	@##~                               Optional. By default, $(CURDIR)/docker-compose.yaml
	@##~ COMPOSE_REMOVE_VOLUMES=true - if passed, remove volumes.
	@##~                               Optional	
	@##~ COMPOSE_NOT_DETACH=true     - if passed, run in not detach mode.
	@##~                               Optional
	@##~ COMPOSE_ENV=PATH            - if passed, run compose with --env-file.
	@##~                               Optional
	@##~ COMPOSE_ENV_EXAMPLE=PATH    - if passed, output use this example file for COMPOSE_ENV.
	@##~                               Optional
	@##~ COMPOSE_RUN_TARGET=TARGET   - if passed, output use COMPOSE_RUN_TARGET/stop for stop compose 
	@##~                               and COMPOSE_RUN_TARGET/logs for output logs in detach mode.
	@##~                               Optional
	@${INCLUDE_DOCKER_UTILS} \
	declare -a __run_compose_args=(); \
	check_compose_params "__run_compose_args"; \
	compose_file="$$(get_compose_file)"; \
	down_args=( \
		"down" \
		"-t" \
		"10" \
		"--remove-orphans" \
	); \
	if [ -n "$${COMPOSE_REMOVE_VOLUMES}" ]; then \
		echo_warn "Volumes will removed!"; \
		down_args+=("-v"); \
	fi; \
	if [ -n "$${COMPOSE_ONLY_STOP}" ]; then \
		target_msg_suf="for file '$$compose_file'"; \
		if [ -n "$$COMPOSE_RUN_TARGET" ]; then \
			target_msg_suf="for target $$COMPOSE_RUN_TARGET"; \
		fi; \
		if ! run_compose "__run_compose_args" "$${down_args[@]}"; then \
			exit_with_err "Cannot stop docker compose $$target_msg_suf"; \
		fi; \
		echo_info "Compose stopped $$target_msg_suf"; \
		exit 0; \
	else \
		run_compose "__run_compose_args" "$${down_args[@]}" || true; \
	fi; \
	up_args=( \
		"up" \
		"--wait-timeout" \
		"30" \
		"--timestamps" \
		"--pull" \
		"missing" \
	); \
	if [ -z "$${COMPOSE_NOT_DETACH}" ]; then \
		up_args+=("-d"); \
	fi; \
	if ! run_compose "__run_compose_args" "$${up_args[@]}"; then \
		exit_with_err "Cannot up docker compose for '$$compose_file'"; \
	fi; \
	if [ -z "$${COMPOSE_NOT_DETACH}" ]; then \
		env_file_arg=""; \
		if [ -n "$${COMPOSE_ENV:-}" ]; then \
			env_file_arg=" --env-file $$COMPOSE_ENV"; \
		fi; \
		echo_info "Docker compose up for file '$$compose_file' in detach mode"; \
		echo_info "For see logs use:"; \
		echo_info "  docker compose -f "$$compose_file"$${env_file_arg} logs -t"; \
		if [ -n "$${COMPOSE_RUN_TARGET:-}" ]; then \
			echo_info "or:"; \
			echo_info " make $${COMPOSE_RUN_TARGET}/logs"; \
		fi; \
		echo_info "For stop use:"; \
		echo_info "  docker compose -f "$$compose_file"$${env_file_arg} down"; \
		if [ -n "$${COMPOSE_RUN_TARGET:-}" ]; then \
			echo_info "or:"; \
			echo_info " make $${COMPOSE_RUN_TARGET:-YOUR_RUN_TARGET_SUFFIX}/stop"; \
		fi; \
	fi

docker/compose/stop: export COMPOSE_ONLY_STOP = true
docker/compose/stop: docker/compose/run ## stop docker compose
	@##~ COMPOSE_FILE=PATH           - docker compose file
	@##~                               Optional. By default, $(CURDIR)/docker-compose.yaml
	@##~ COMPOSE_ENV=PATH            - if passed, run compose with --env-file.
	@##~                               If you pass COMPOSE_ENV to docker/compose/run should passed
	@##~                               Optional
	@##~ COMPOSE_REMOVE_VOLUMES=true - if passed, remove volumes.
	@##~                               Optional
	@${INCLUDE_DOCKER_UTILS} \
	if ! has_not_docker_compose_containers "$$COMPOSE_FILE"; then \
		exit_with_err "Compose '$$COMPOSE_FILE' was not stop"; \
	fi

docker/compose/logs: check/installed/docker/compose ## show logs for docker compose
	@##~ COMPOSE_FILE=PATH - docker compose file
	@##~                     Optional. By default, $(CURDIR)/docker-compose.yaml
	@##~ COMPOSE_ENV=PATH  - if passed, run compose with --env-file.
	@##~                     If you pass COMPOSE_ENV to docker/compose/run should passed
	@##~                     Optional
	@##~ FOLLOW=true       - if passed, follow logs.
	@##~                     Optional
	@##~ NO_TIMES=true     - if passed, no print timestamps.
	@##~                     Optional
	@##~ SERVICE=NAME      - if passed, output logs only for passed service NAME.
	@##~                     Also, no output log prefix.
	@##~                     Optional
	@##~ SINCE=RELATIVE    - if passed, output last logs from relative timestamp
	@##~                     Can be 1s for seconds, 1m for minutes
	@##~                     Optional
	@##~ LAST=LINES_NUM    - if passed, output last numbers of logs
	@##~                     Optional
	@${INCLUDE_DOCKER_UTILS} \
	__logs_compose_args=(); \
	check_compose_params "__logs_compose_args"; \
	args=( \
		"logs" \
	); \
	if [ -z "$${NO_TIMES:-}" ]; then \
		args+=("-t"); \
	fi; \
	if [ -n "$${FOLLOW:-}" ]; then \
		args+=("-f"); \
	fi; \
	if [ -n "$${LAST:-}" ]; then \
		args+=( \
			"-n" \
			"$$LAST" \
		); \
	fi; \
	if [ -n "$${SINCE:-}" ]; then \
		args+=( \
			"--since" \
			"$$SINCE" \
		); \
	fi; \
	if [ -n "$${SERVICE:-}" ]; then \
		args+=("--no-log-prefix"); \
		args+=("$$SERVICE"); \
	fi; \
	run_compose "__logs_compose_args" "$${args[@]}"

.PHONY: check/installed/docker check/installed/docker/compose docker/compose/run docker/compose/stop docker/compose/logs
