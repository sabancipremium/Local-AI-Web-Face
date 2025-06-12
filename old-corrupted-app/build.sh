#!/bin/bash

# Ollama Chat Build Script
# This script builds the Ollama Chat macOS application

set -e

echo "🚀 Building Ollama Chat..."

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode command line tools not found. Please install Xcode."
    exit 1
fi

# Set build configuration
CONFIGURATION="Release"
SCHEME="OllamaChat"
WORKSPACE="OllamaChat.xcodeproj"

# Build the application
echo "📦 Building application..."
xcodebuild -project "$WORKSPACE" \
           -scheme "$SCHEME" \
           -configuration "$CONFIGURATION" \
           -derivedDataPath "build" \
           build

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build completed successfully!"
    echo "📍 Application built at: build/Build/Products/$CONFIGURATION/OllamaChat.app"
    
    # Optional: Create a disk image
    read -p "📀 Create disk image (DMG)? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "💿 Creating disk image..."
        
        DMG_NAME="OllamaChat-v1.0"
        APP_PATH="build/Build/Products/$CONFIGURATION/OllamaChat.app"
        
        # Create temporary directory
        mkdir -p "dmg_temp"
        cp -R "$APP_PATH" "dmg_temp/"
        
        # Create symbolic link to Applications
        ln -sf /Applications "dmg_temp/Applications"
        
        # Create DMG
        hdiutil create -volname "$DMG_NAME" \
                      -srcfolder "dmg_temp" \
                      -ov -format UDZO \
                      "$DMG_NAME.dmg"
        
        # Cleanup
        rm -rf "dmg_temp"
        
        echo "✅ Disk image created: $DMG_NAME.dmg"
    fi
    
else
    echo "❌ Build failed!"
    exit 1
fi

echo "🎉 Build process complete!"
