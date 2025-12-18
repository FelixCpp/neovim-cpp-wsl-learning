DOCKER_IMAGE_NAME ?= mingw-cpp20
BUILD_DIR ?= build
BUILD_TYPE ?= Debug

create_docker:
	docker build -t $(DOCKER_IMAGE_NAME) .

generate:
	@echo "==> Generating project files..."
	docker run --rm -it -u "$(shell id -u)":"$(shell id -g)" -v "$(shell pwd)":"$(shell pwd)" -w "$(shell pwd)" $(DOCKER_IMAGE_NAME) cmake -B $(BUILD_DIR) -DCMAKE_TOOLCHAIN_FILE="./mingw-toolchain.cmake" -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -G "Ninja"

build: generate
	@echo "==> Building project..."
	docker run --rm -it -u $(shell id -u):$(shell id -g) -v $(shell pwd):$(shell pwd) -w $(shell pwd) $(DOCKER_IMAGE_NAME) cmake --build build
	@if [ -f $(BUILD_DIR)/compile_commands.json ]; then \
		cp $(BUILD_DIR)/compile_commands.json .; \
	fi

run: build
	@echo "==> Launching program..."
	@echo "... Searching *.exe file ..."
	@EXECUTABLE_FILE=$$(find $(BUILD_DIR) -maxdepth 1 -name "*.exe" -type f | head -n 1); \
		if [ -n "$$EXECUTABLE_FILE" ]; then \
			echo "Found executable: $$EXECUTABLE_FILE"; \
			./$$EXECUTABLE_FILE; \
		else \
			echo "Haven't found a *.exe file inside the $(BUILD_DIR) directory"; \
			exit 1; \
		fi

clean:
	@echo "==> Cleaning project files..."
	@if [ -d $(BUILD_DIR) ]; then \
		echo "Deleting directory \"$(BUILD_DIR)\""; \
		docker run --rm -it -u $(shell id -u):$(shell id -g) -v $(shell pwd):$(shell pwd) -w $(shell pwd) $(DOCKER_IMAGE_NAME) rm -rd $(BUILD_DIR); \
	else \
		echo "Could't find \"$(BUILD_DIR)\" directory. Nothing to clean up"; \
	fi
