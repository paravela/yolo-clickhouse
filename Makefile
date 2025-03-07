# Makefile for MCP-ClickHouse server
# Use 'make help' to see available targets

# Configuration variables
IMAGE_NAME = pavavela/yolo-mcp
VERSION ?= latest

# Docker build flags
DOCKER_BUILD_FLAGS ?= --no-cache

.PHONY: help build test clean push push-latest

# Default target - show help
help:
	@echo "=== MCP-CLICKHOUSE MAKEFILE TARGETS ==="
	@echo "build       - Build Docker image tagged as $(IMAGE_NAME):$(VERSION)"
	@echo "test        - Test Docker image by running test_mcp.sh script"
	@echo "push        - Push image to Docker registry with current version"
	@echo "push-latest - Push image tagged as 'latest' to Docker registry"
	@echo "clean       - Clean up Docker images"
	@echo ""
	@echo "Specify VERSION to override default version tag:"
	@echo "  make build VERSION=1.0.0"

# Build Docker image
build:
	@echo "Building Docker image $(IMAGE_NAME):$(VERSION)..."
	docker build $(DOCKER_BUILD_FLAGS) -t $(IMAGE_NAME):$(VERSION) .
	@echo "Docker image built: $(IMAGE_NAME):$(VERSION)"

# Test Docker image
test: build
	@echo "Testing Docker image $(IMAGE_NAME):$(VERSION)..."
	./test_mcp.sh

# Push Docker image to registry
push: build
	@echo "Pushing Docker image $(IMAGE_NAME):$(VERSION) to registry..."
	docker push $(IMAGE_NAME):$(VERSION)
	@echo "Docker image pushed successfully"

# Push Docker image as latest
push-latest: build
	@echo "Tagging Docker image as latest..."
	docker tag $(IMAGE_NAME):$(VERSION) $(IMAGE_NAME):latest
	@echo "Pushing Docker image $(IMAGE_NAME):latest to registry..."
	docker push $(IMAGE_NAME):latest
	@echo "Docker image pushed as latest successfully"

# Clean up Docker images
clean:
	@echo "Cleaning up Docker images..."
	-docker rmi $(IMAGE_NAME):$(VERSION) 2>/dev/null || true
	-docker rmi $(IMAGE_NAME):latest 2>/dev/null || true
	@echo "Cleanup completed"