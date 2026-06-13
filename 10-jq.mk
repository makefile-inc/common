

ifeq ($(OS_NAME), Linux)
else ifeq ($(OS_NAME), Darwin)
endif

ifeq ($(PLATFORM_NAME), x86_64)
else ifeq ($(PLATFORM_NAME), arm64)
endif
