# Makefile for Ollama Chat macOS App

.PHONY: help build clean install test archive dmg setup

# Default target
help:
	@echo "Ollama Chat Build System"
	@echo "========================"
	@echo ""
	@echo "Available targets:"
	@echo "  build     - Build the application in Debug mode"
	@echo "  release   - Build the application in Release mode"
	@echo "  clean     - Clean build artifacts"
	@echo "  install   - Install to /Applications"
	@echo "  test      - Run tests"
	@echo "  archive   - Create archive for distribution"
	@echo "  dmg       - Create disk image"
	@echo "  setup     - Setup development environment"
	@echo "  help      - Show this help message"

# Variables
PROJECT = OllamaChat.xcodeproj
SCHEME = OllamaChat
CONFIG_DEBUG = Debug
CONFIG_RELEASE = Release
DERIVED_DATA = build
APP_NAME = OllamaChat.app

# Build targets
build:
	@echo "🔨 Building Ollama Chat (Debug)..."
	xcodebuild -project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIG_DEBUG) \
		-derivedDataPath $(DERIVED_DATA) \
		build

release:
	@echo "🚀 Building Ollama Chat (Release)..."
	xcodebuild -project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIG_RELEASE) \
		-derivedDataPath $(DERIVED_DATA) \
		build

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	rm -rf $(DERIVED_DATA)
	xcodebuild -project $(PROJECT) clean

# Install to Applications folder
install: release
	@echo "📦 Installing to /Applications..."
	sudo cp -R "$(DERIVED_DATA)/Build/Products/$(CONFIG_RELEASE)/$(APP_NAME)" /Applications/
	@echo "✅ Installed successfully!"

# Run tests
test:
	@echo "🧪 Running tests..."
	xcodebuild -project $(PROJECT) \
		-scheme $(SCHEME) \
		-derivedDataPath $(DERIVED_DATA) \
		test

# Create archive
archive:
	@echo "📦 Creating archive..."
	xcodebuild -project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIG_RELEASE) \
		-derivedDataPath $(DERIVED_DATA) \
		archive \
		-archivePath "$(DERIVED_DATA)/$(SCHEME).xcarchive"

# Create DMG
dmg: release
	@echo "💿 Creating disk image..."
	./build.sh

# Setup development environment
setup:
	@echo "⚙️  Setting up development environment..."
	@echo "Checking for Xcode..."
	@if ! command -v xcodebuild > /dev/null; then \
		echo "❌ Xcode not found. Please install Xcode from the App Store."; \
		exit 1; \
	fi
	@echo "✅ Xcode found"
	
	@echo "Checking for Ollama..."
	@if ! command -v ollama > /dev/null; then \
		echo "⚠️  Ollama not found. Installing via Homebrew..."; \
		brew install ollama; \
	fi
	@echo "✅ Ollama found"
	
	@echo "✅ Development environment setup complete!"

# Development helpers
dev-clean: clean build
	@echo "🔄 Clean build complete"

quick-build:
	@echo "⚡ Quick build (no clean)..."
	xcodebuild -project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIG_DEBUG) \
		-derivedDataPath $(DERIVED_DATA) \
		build

# Project information
info:
	@echo "Project Information"
	@echo "==================="
	@echo "Project: $(PROJECT)"
	@echo "Scheme: $(SCHEME)"
	@echo "Configurations: $(CONFIG_DEBUG), $(CONFIG_RELEASE)"
	@echo "Derived Data: $(DERIVED_DATA)"
	@echo "App Name: $(APP_NAME)"
