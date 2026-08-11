# Copyright 2026
# license that can be found in the LICENSE file.

# INCLUDE_SPLIT - add next sh functions:
#   trim_spaces_left - trim whitespaces from left
#     Arguments:
#       $1 - string to trim
#   trim_spaces_right - trim whitespaces from right
#     Arguments:
#       $1 - string to trim
#   trim_spaces - trim whitespaces from right and left
#     Arguments:
#       $1 - string to trim
#   split_by - split string by separator to global array
#     Arguments:
#       $1 - separator (can be multi-character)
#       $2 - name of destination array variable
#       $3 - string to split
#       $4 - function name to transform all values (like trim_spaces). got string argument and returns string. Optional
#   split_by_comma - split string by comma-separator to global array
#     Arguments:
#       $1 - name of destination array variable
#       $2 - string to split
#       $3 - function name to transform all values (like trim_spaces). got string argument and returns string. Optional
#   split_by_space - split string by space-separator to global array
#     Arguments:
#       $1 - name of destination array variable
#       $2 - string to split
#       $3 - function name to transform all values (like trim_spaces). got string argument and returns string. Optional
#   split_by_new_line - split string by new-line-separator to global array
#     Arguments:
#       $1 - name of destination array variable
#       $2 - string to split
#       $3 - function name to transform all values (like trim_spaces). got string argument and returns string. Optional
# Example include:
#   @${INCLUDE_ECHO} \ - slash is required!
# Example:
#   include *.mk
#   test/trim:
# 	    @${INCLUDE_SPLIT} \
# 	    b="$$(trim_spaces $$'\n  \t\n\t   from begin')"; \
# 	    e="$$(trim_spaces $$'from end\n  \t\n\t  ')"; \
# 	    m="$$(trim_spaces $$'\n  \t\n\tin middle\n  \t\n\t  ')"; \
# 	    n="$$(trim_spaces "no trim")"; \
# 	    echo "'$$b'";\
# 	    echo "'$$e'";\
# 	    echo "'$$m'";\
# 	    echo "'$$n'"
# 	test/split:
# 		@${INCLUDE_SPLIT} \
#		function print_arr() { \
#			local function_array=("$$@"); \
#			if [ "$${#function_array[@]}" -eq 0 ]; then \
#				echo "Got empty array"; \
#				return; \
#			fi; \
#    		for item in "$${function_array[@]}"; do \
#        		echo "Value: '$$item'"; \
#    		done; \
#		}; \
#		function own_transform_fun() { \
#			echo -n "transformed: '$${1:-}'"; \
#		}; \
# 		comma="a,b c,d"; \
# 		split_by_comma "comma_arr" "$$comma"; \
# 		echo "Comma-separated:"; \
# 		print_arr "$${comma_arr[@]}"; \
# 		new_line=$$'Hello with\n Name'; \
# 		split_by_new_line "new_line_arr" "$$new_line"; \
# 		echo "New line-separated:"; \
# 		print_arr "$${new_line_arr[@]}"; \
# 		spaces=$$'val ba bbval\nccc'; \
# 		split_by_space "spaces_arr" "$$spaces"; \
# 		echo "Spaces-separated:"; \
# 		print_arr "$${spaces_arr[@]}"; \
# 		own=$$'val ba. bbval\nccc'; \
# 		split_by '.' "own_arr" "$$own"; \
# 		echo "Dot-separated:"; \
# 		print_arr "$${own_arr[@]}"; \
# 		multi=$$'val ba\n b|||bval|||ccc'; \
# 		split_by '|||' "multi_arr" "$$multi"; \
# 		echo "Multi-separated:"; \
# 		print_arr "$${multi_arr[@]}"
#		print_arr "$${multi_arr[@]}"; \
#		empty=""; \
#		split_by_comma "empty_arr" "$$empty"; \
#		echo "Empty:"; \
#		print_arr "$${empty_arr[@]}"; \
#		trim_left=$$'a, b b,,  c,\n d ,e f,'; \
#		split_by_comma "trim_left_arr" "$$trim_left" "trim_spaces_left"; \
#		echo "Transform trim left:"; \
#		print_arr "$${trim_left_arr[@]}"; \
#		trim_right=$$'a ,b b ,  c  ,d \n,e f'; \
#		split_by_comma "trim_right_arr" "$$trim_right" "trim_spaces_right"; \
#		echo "Transform trim right:"; \
#		print_arr "$${trim_right_arr[@]}"; \
#		trim_all=$$' a , b b ,  c,\n d \n,e f,g '; \
#		split_by_comma "trim_all_arr" "$$trim_all" "trim_spaces"; \
#		echo "Transform trim all:"; \
#		print_arr "$${trim_all_arr[@]}"; \
#		trim_all_empty=""; \
#		split_by_comma "trim_all_empty_arr" "$$trim_all_empty" "trim_spaces"; \
#		echo "Transform trim all empty:"; \
#		print_arr "$${trim_all_empty_arr[@]}"; \
#		transform_own="a||b c|| de||g"; \
#		split_by "||" "transform_own_arr" "$$transform_own" "own_transform_fun"; \
#		echo "Transform own:"; \
#		print_arr "$${transform_own_arr[@]}"
# Can be included multiple times because sh redeclare function without error
define INCLUDE_SPLIT
function trim_spaces_left() { \
    local trimmed="$${1:-}"; \
    echo -n "$${trimmed#"$${trimmed%%[![:space:]]*}"}"; \
}; \
function trim_spaces_right() { \
    local trimmed="$${1:-}"; \
    echo -n "$${trimmed%"$${trimmed##*[![:space:]]}"}"; \
}; \
function trim_spaces() { \
    local trimmed="$${1:-}"; \
    trimmed="$$(trim_spaces_left "$$trimmed")"; \
    trimmed="$$(trim_spaces_right "$$trimmed")"; \
    echo -n "$$trimmed"; \
}; \
function split_by() { \
	local _sep="$${1:-}"; \
	if [ -z "$$_sep" ]; then \
		echo -e "${RED_COLOR}Separator for split_by not passed as first arg ${NO_COLOR}" >&2; \
		exit 1; \
	fi; \
	_sep="$$(printf '%s\n' "$$_sep" | sed 's/[]\/$$*.^[]/\\&/g' | sed ':a;N;$$!ba;s/\n/\\n/g')"; \
	local _dest="$${2:-}"; \
	if [ -z "$$_dest" ]; then \
		echo -e "${RED_COLOR}Destination array for split_by not passed as second arg ${NO_COLOR}" >&2; \
		exit 1; \
	fi; \
	local _str="$${3:-}"; \
	readarray -t -d '' "$$_dest" < <(sed -z "s/$$_sep/\x00/g" < <(printf '%s' "$$_str")); \
	local _transform="$${4:-}"; \
	if [ -n "$$_transform" ]; then \
		local -n target_array="$$_dest"; \
		for _indx in "$${!target_array[@]}"; do \
    		target_array[_indx]="$$("$$_transform" "$${target_array[_indx]}")"; \
		done; \
	fi; \
}; \
function split_by_comma() { \
	local _dest="$${1:-}"; \
	local _str="$${2:-}"; \
	local _transform="$${3:-}"; \
	split_by ',' "$$_dest" "$$_str" "$$_transform"; \
}; \
function split_by_space() { \
	local _dest="$${1:-}"; \
	local _str="$${2:-}"; \
	local _transform="$${3:-}"; \
	split_by ' ' "$$_dest" "$$_str" "$$_transform"; \
}; \
function split_by_new_line() { \
	local _dest="$${1:-}"; \
	local _str="$${2:-}"; \
	local _transform="$${3:-}"; \
	split_by $$'\n' "$$_dest" "$$_str" "$$_transform"; \
};
endef

# INCLUDE_STRINGS - add next sh functions:
#   append_str_with_separator - append string to end with separator prefix and return
#     If append only one string, prefix will not add.
#     End of string always does not contains separator.
#     If append string is empty, return passed string.
#     If string for add is empty append string without separator..
#     Arguments:
#       $1 - separator, can be empty
#       $2 - string for add
#       $3 - append string
#   append_str_with_new_line - call append_str_with_separator with new line separator
#     Arguments:
#       $1 - string for add
#       $2 - append string
#   shift_str_on - split string by new line and add prefix (shift) for each line
#     Arguments:
#       $1 - string to append prefix (shift)
#       $2 - count of prefixes to add. if not passed or empty will 1
#       $3 - prefix to add. if not passed or empty will use one space prefix
#   shift_str_on_tab - call shift_str_on with tab prefix
#     Arguments:
#       $1 - string to append prefix (shift)
#       $2 - count of prefixes to add. if not passed or empty will 1
#   escape_re_str - escape string as regexp string (to pass to grep).
#     Arguments:
#       $1 - string to escape
# Example include:
#   @${INCLUDE_STRINGS} \ - slash is required!
# Example:
# 	include *.mk
# 	_test/append-str-with:
# 		@${INCLUDE_STRINGS} \
#		empty=""; \
#		empty="$$(append_str_with_separator "|" "$$empty" "first")"; \
#		echo "Empty after add first: '$$empty'"; \
#		empty="$$(append_str_with_separator "|" "$$empty" "second")"; \
#		echo "Empty after add second: '$$empty'"; \
#		empty="$$(append_str_with_separator "|" "$$empty" "third")"; \
#		echo "Empty after add third: '$$empty'"; \
#		not_empty="not empty"; \
#		not_empty="$$(append_str_with_separator " | " "$$not_empty" "first")"; \
#		echo "Not empty after add first: '$$not_empty'"; \
#		not_empty="$$(append_str_with_separator " | " "$$not_empty" "second")"; \
#		echo "Not empty after add second: '$$not_empty'"; \
#		not_empty="$$(append_str_with_separator " | " "$$not_empty" "third")"; \
#		echo "Not empty after add third: '$$not_empty'"; \
#		empty_with_empty_add=""; \
#		empty_with_empty_add="$$(append_str_with_separator "; " "$$empty_with_empty_add" "")"; \
#		echo "Empty with empty add - add empty string: '$$empty_with_empty_add'"; \
#		empty_with_empty_add="$$(append_str_with_separator "; " "$$empty_with_empty_add" "first")"; \
#		echo "Empty with empty add - after add first: '$$empty_with_empty_add'"; \
#		empty_with_empty_add="$$(append_str_with_separator "; " "$$empty_with_empty_add" "")"; \
#		echo "Empty with empty add - second empty: '$$empty_with_empty_add'"; \
#		empty_with_empty_add="$$(append_str_with_separator "; " "$$empty_with_empty_add" "second")"; \
#		echo "Empty with empty add - add second: '$$empty_with_empty_add'"; \
#		append_new_line=""; \
#		append_new_line="$$(append_str_with_new_line "$$append_new_line" "")"; \
#		echo "Append with new line - add empty: '$$append_new_line'"; \
#		append_new_line="$$(append_str_with_new_line "$$append_new_line" "first str")"; \
#		echo "Append with new line - add first str: '$$append_new_line'"; \
#		append_new_line="$$(append_str_with_new_line "$$append_new_line" "second str")"; \
#		echo "Append with new line - add second str: '$$append_new_line'"
#
#	_test/shift-str-on:
#		@${INCLUDE_STRINGS} \
#		new_line=$$'\n'; \
#		one_string="one string"; \
#		one_string="$$(shift_str_on "$$one_string" "5" " ")"; \
#		echo "One string: '$$one_string'"; \
#		two_strings="first string$${new_line}second string"; \
#		two_strings="$$(shift_str_on "$$two_strings" "1" " - ")"; \
#		echo "Two strings: '$$two_strings'"; \
#		three_strings="first string$${new_line}second string$${new_line}third string"; \
#		three_strings="$$(shift_str_on "$$three_strings" "1" "** ")"; \
#		echo "three strings:"; \
#		echo "$$three_strings"; \
#		three_strings="$$(shift_str_on_tab "$$three_strings" "2")"; \
#		echo "three strings after shift on 2 tabs:"; \
#		echo "$$three_strings"
#	_test/escape-re:
#		@${INCLUDE_STRINGS} \
#		${INCLUDE_ECHO} \
#		not_need="test str"; \
#		for_escape="\$$var {input} [test-str] (**OOP**) \\do | not_do + ^HOME^ ."; \
#		escaped_not_need="$$(escape_re_str "$$not_need")"; \
#		escaped_for_escape="$$(escape_re_str "$$for_escape")"; \
#		echo_info "Escape re '$$not_need': '$$escaped_not_need'"; \
#		echo_info "Escape re '$$for_escape': '$$escaped_for_escape'"
# Can be included multiple times because sh redeclare function without error
define INCLUDE_STRINGS
${INCLUDE_SPLIT} \
function escape_re_str() { \
	local str="$${1:-}"; \
	if [ -z "$$str" ]; then \
		echo -n ""; \
		return 0; \
	fi; \
	local escaped="$$(printf '%s' "$$str" | sed 's/[.[\*^$$()+?{|]/\\&/g')"; \
	echo -n "$$escaped"; \
}; \
function append_str_with_separator() { \
	local sep="$${1:-}"; \
	local str="$${2:-}"; \
	local app="$${3:-}"; \
	if [ -n "$$app" ]; then \
		if [ -z "$$str" ]; then \
			str="$$app"; \
		else \
			str="$${str}$${sep}$${app}"; \
		fi; \
	fi; \
	echo -n "$$str"; \
}; \
function append_str_with_new_line() { \
	local new_line=$$'\n'; \
	local str="$${1:-}"; \
	local app="$${2:-}"; \
	echo -n "$$(append_str_with_separator "$$new_line" "$$str" "$$app")"; \
}; \
__split_for_shift_str_on_arr=(); \
function shift_str_on() { \
	__split_for_shift_str_on_arr=(); \
	local str="$${1:-}"; \
	if [ -z "$$str" ]; then \
		echo -n "$$str"; \
		return 0; \
	fi; \
	local new_line=$$'\n'; \
	local count="$${2:-}"; \
	local sep="$${3:-}"; \
	if [ -z "$$count" ]; then \
		count="1"; \
	fi; \
	if [ -z "$$sep" ]; then \
		sep=" "; \
	fi; \
	local full_sep=""; \
	for ii in $$(seq "$$count"); do \
		full_sep="$${full_sep}$${sep}"; \
	done; \
	split_by_new_line "__split_for_shift_str_on_arr" "$$str"; \
	local res_s=""; \
	for _str_to_shift in "$${__split_for_shift_str_on_arr[@]}"; do \
		res_s="$$(append_str_with_separator "$${new_line}$${full_sep}" "$$res_s" "$$_str_to_shift")"; \
	done; \
	__split_for_shift_str_on_arr=(); \
	echo -n "$${full_sep}$$res_s"; \
}; \
function shift_str_on_tab() { \
	local tab_sep=$$'\t'; \
	local str="$${1:-}"; \
	local count="$${2:-}"; \
	str="$$(shift_str_on "$$str" "$$count" "$$tab_sep")"; \
	echo -n "$$str"; \
};
endef
