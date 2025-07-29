# Container image configuration
IMAGE_REG ?= docker.io
IMAGE_REPO ?= writetoritika/dotnet-monitoring
IMAGE_TAG ?= latest
IMAGE_FULL := $(IMAGE_REG)/$(IMAGE_REPO):$(IMAGE_TAG)

# Azure deployment configuration
AZURE_RES_GROUP ?= demoapps
AZURE_REGION ?= northeurope
AZURE_APP_NAME ?= dotnet-demoapp

# API test configuration
TEST_HOST ?= localhost:5000

# Directory paths
SRC_DIR := src
TEST_DIR := tests

.PHONY: help lint lint-fix image push run deploy undeploy test test-report test-api clean .EXPORT_ALL_VARIABLES
.DEFAULT_GOAL := help

help: ## 💬 Show help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

lint: ## 🔎 Lint source files using dotnet-format
	@dotnet format --help > /dev/null 2>&1 || dotnet tool install --global dotnet-format
	dotnet format --verbosity diag $(SRC_DIR)

image: ## 🔨 Build container image from Dockerfile
	@echo "🔨 Building image: $(IMAGE_FULL)"
	docker build . --file build/Dockerfile --tag $(IMAGE_FULL)

push: ## 📤 Push container image to Docker registry
	@echo "📤 Pushing image: $(IMAGE_FULL)"
	@if ! docker image inspect $(IMAGE_FULL) > /dev/null 2>&1; then \
		echo "❌ Image $(IMAGE_FULL) not found. Run 'make image' first."; \
		exit 1; \
	fi
	docker push $(IMAGE_FULL)

run: ## 🏃‍♂️ Run the app locally
	dotnet watch --project $(SRC_DIR)/dotnet-demoapp.csproj

deploy: ## 🚀 Deploy to Azure Container App
	@echo "🚀 Deploying to Azure..."
	az group create --resource-group $(AZURE_RES_GROUP) --location $(AZURE_REGION) -o table
	az deployment group create --template-file deploy/container-app.bicep \
		--resource-group $(AZURE_RES_GROUP) \
		--parameters appName=$(AZURE_APP_NAME) \
		--parameters image=$(IMAGE_FULL) -o table
	@sleep 2
	@echo "✅ App deployed at: $$(az deployment group show --resource-group $(AZURE_RES_GROUP) --name container-app --query 'properties.outputs.appURL.value' -o tsv)/"

undeploy: ## 💀 Delete Azure Resource Group
	@echo "⚠️ Deleting resource group: $(AZURE_RES_GROUP)"
	az group delete --name $(AZURE_RES_GROUP) --yes --no-wait -o table

test: ## ✅ Run unit tests
	dotnet test $(TEST_DIR)/tests.csproj

test-report: ## 📊 Generate test reports
	rm -rf $(TEST_DIR)/TestResults
	dotnet test $(TEST_DIR)/tests.csproj --test-adapter-path:. --logger:junit --logger:html

test-api: .EXPORT_ALL_VARIABLES ## 🔬 Run Postman/Newman API tests (server must be running)
	cd $(TEST_DIR) && npm install newman && ./node_modules/.bin/newman run ./postman_collection.json --env-var apphost=$(TEST_HOST)

clean: ## 🧹 Clean build/test artifacts
	rm -rf $(TEST_DIR)/node_modules \
	       $(TEST_DIR)/package* \
	       $(TEST_DIR)/TestResults \
	       $(TEST_DIR)/bin $(TEST_DIR)/obj \
	       $(SRC_DIR)/bin $(SRC_DIR)/obj
