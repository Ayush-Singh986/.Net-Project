# Image config
IMAGE_REG ?= docker.io
IMAGE_REPO ?= writetoritika/dotnet-monitoring
IMAGE_TAG ?= latest
IMAGE_FULL := $(IMAGE_REG)/$(IMAGE_REPO):$(IMAGE_TAG)

# Directories
SRC_DIR := src
TEST_DIR := tests

.PHONY: help lint lint-fix image push run test test-report test-api clean .EXPORT_ALL_VARIABLES
.DEFAULT_GOAL := help

help: ## 💬 Show help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

lint: ## 🔍 Lint and format the code
	@dotnet format --help > /dev/null 2>&1 || dotnet tool install --global dotnet-format
	dotnet format --verbosity diag $(SRC_DIR)

image: ## 🔨 Build container image
	@echo "📦 Building image: $(IMAGE_FULL)"
	docker build . --file build/Dockerfile --tag $(IMAGE_FULL)

push: ## 🚀 Push image to DockerHub
	@echo "🚀 Pushing image: $(IMAGE_FULL)"
	@if ! docker image inspect $(IMAGE_FULL) > /dev/null 2>&1; then \
		echo "❌ Image not found: $(IMAGE_FULL). Run 'make image' first."; \
		exit 1; \
	fi
	docker push $(IMAGE_FULL)

run: ## 🏃 Run locally
	dotnet watch --project $(SRC_DIR)/dotnet-demoapp.csproj

test: ## ✅ Run unit tests
	dotnet test $(TEST_DIR)/tests.csproj

test-report: ## 📄 Unit tests with reports
	rm -rf $(TEST_DIR)/TestResults
	dotnet test $(TEST_DIR)/tests.csproj --test-adapter-path:. --logger:junit --logger:html

clean: ## 🧹 Clean everything
	rm -rf $(TEST_DIR)/node_modules \
	       $(TEST_DIR)/package* \
	       $(TEST_DIR)/TestResults \
	       $(TEST_DIR)/bin $(TEST_DIR)/obj \
	       $(SRC_DIR)/bin $(SRC_DIR)/obj
