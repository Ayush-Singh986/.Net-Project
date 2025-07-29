# Image configuration
IMAGE_REG ?= docker.io
IMAGE_REPO ?= ayush244/dotnet-monitoring
IMAGE_TAG ?= latest

# Directory settings
SRC_DIR := src
TEST_DIR := tests

.PHONY: help lint image push run test test-report test-api clean
.DEFAULT_GOAL := help

help: ## 💬 Show help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

lint: ## 🔍 Lint code
	@dotnet format --help > /dev/null 2>&1 || dotnet tool install --global dotnet-format
	dotnet format --verbosity diag ./$(SRC_DIR)

image: ## 🔨 Build Docker image
	@echo "🚧 Building image: $(IMAGE_REG)/$(IMAGE_REPO):$(IMAGE_TAG)"
	docker build . -f build/Dockerfile -t $(IMAGE_REG)/$(IMAGE_REPO):$(IMAGE_TAG)

push: ## 📤 Push Docker image
	@echo "🚀 Pushing image: $(IMAGE_REG)/$(IMAGE_REPO):$(IMAGE_TAG)"
	docker push $(IMAGE_REG)/$(IMAGE_REPO):$(IMAGE_TAG)

run: ## 🏃 Run locally with dotnet CLI
	dotnet watch --project $(SRC_DIR)/dotnet-demoapp.csproj

test: ## ✅ Run unit tests
	dotnet test $(TEST_DIR)/tests.csproj

test-report: ## 🧪 Run tests with report (Jenkins-compatible)
	rm -rf $(TEST_DIR)/TestResults
	dotnet test $(TEST_DIR)/tests.csproj --logger "trx;LogFileName=test_results.trx"
	trx2junit $(TEST_DIR)/TestResults/test_results.trx

test-api: ## 🌐 Run integration API tests
	cd tests && npm install newman && \
	./node_modules/.bin/newman run ./postman_collection.json --env-var apphost=localhost:5000

clean: ## 🧹 Clean project files
	rm -rf $(TEST_DIR)/node_modules $(TEST_DIR)/package* $(TEST_DIR)/TestResults
	rm -rf $(SRC_DIR)/bin $(SRC_DIR)/obj $(TEST_DIR)/bin $(TEST_DIR)/obj
