# Copyright 2026
# license that can be found in the LICENSE file.

# NOW_MICROSECONDS - output curreint unix-time with microseconds 
# DO NOT in $(call ...)
# Example:
#   include *.mk
#   test/duration:
#	      @start="$$(${NOW_MICROSECONDS})"; \
#	      echo "$$start"
define NOW_MICROSECONDS
date +"%s%6N"
endef

# HUMAN_DURATION_MICROSECONDS_SCRIPT - render script that calculate and output in the humman way duration (with microseconds)
# DO NOT in $(call ...)
# $1 - start microseconds int
# $2 - end microseconds int
# Example:
#   include *.mk
#   test/duration:
#	      @start="$$(${NOW_MICROSECONDS})"; \
#	      sleep 2; \
#	      end="$$(${NOW_MICROSECONDS})"; \
#	      dur="$$(${HUMAN_DURATION_MICROSECONDS} "$$start" "$$end")"; \
#	      echo "Duration $$dur"
define HUMAN_DURATION_MICROSECONDS_SCRIPT
start="$$0"; \
end="$$1"; \
duration_micros="$$((end - start))"; \
hours=$$(( duration_micros / 3600000000 )); \
minutes=$$(( (duration_micros / 60000000) % 60 )); \
seconds=$$(( (duration_micros / 1000000) % 60 )); \
micros=$$(( duration_micros % 1000000 )); \
out="$$(printf "%02d.%06ds" $$seconds $$micros)"; \
if [ "$$hours" -gt 0 ]; then \
  out="$$(printf "%02dh %02dm" $$hours $$minutes) $$out"; \
elif [ "$$minutes" -gt 0 ]; then \
  out="$$(printf "%02dm" $$minutes) $$out"; \
fi; \
echo -n "$$out"
endef

# HUMAN_DURATION_MICROSECONDS - calculate and output in the humman way duration (with microseconds)
# DO NOT in $(call ...)
# $1 - start microseconds int
# $2 - end microseconds int
# Example:
#   include *.mk
#   test/duration:
#	      @start="$$(${NOW_MICROSECONDS})"; \
#	      sleep 2; \
#	      end="$$(${NOW_MICROSECONDS})"; \
#	      dur="$$(${HUMAN_DURATION_MICROSECONDS} "$$start" "$$end")"; \
#	      echo "Duration $$dur"
define HUMAN_DURATION_MICROSECONDS
sh -c ' \
${HUMAN_DURATION_MICROSECONDS_SCRIPT}'
endef

# RUN_WITH_DURATION - prepare script to run target, calculate run time and output duration
# DO NOT in $(call ...)
# $1 - target name
# $2 - humman description on target
# Example:
#   include *.mk
#   test/sleep-exec-ok:
#	      @sleep 2; \
#	      echo "Do ok"; \
#	      exit 0
#   test/run-with-duration/ok:
#       @${RUN_WITH_DURATION} "test/sleep-exec-ok" "Do with ok"
#   test/run-with-duration/fail:
#	      @${RUN_WITH_DURATION} "test/sleep-exec-fail" "Do with fail"
define RUN_WITH_DURATION 
sh -c ' \
_start_t="$$(${NOW_MICROSECONDS})"; \
$(MAKE) "$$0"; \
ret="$$?"; \
_end_t="$$(${NOW_MICROSECONDS})"; \
_dur_t="$$(sh -c '\''${HUMAN_DURATION_MICROSECONDS_SCRIPT}'\'' "$$_start_t" "$$_end_t")"; \
if [ "$$ret" -eq 0 ]; then \
  echo "${GREEN_COLOR}$$1 $$_dur_t${NO_COLOR}"; \
  exit 0; \
fi; \
echo "${RED_COLOR}$$1 failed: $$_dur_t${NO_COLOR}"; \
exit $$ret'
endef