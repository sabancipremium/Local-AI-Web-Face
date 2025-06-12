#!/bin/bash

# Development Launch Script for Ollama Chat
# This script helps with development workflow

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Ollama Chat Development Launcher${NC}"
echo "======================================="

# Function to check if Ollama is running
check_ollama() {
    if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Ollama is running${NC}"
        return 0
    else
        echo -e "${RED}❌ Ollama is not running${NC}"
        return 1
    fi
}

# Function to start Ollama
start_ollama() {
    echo -e "${YELLOW}🔄 Starting Ollama service...${NC}"
    if command -v ollama >/dev/null 2>&1; then
        ollama serve &
        sleep 3
        if check_ollama; then
            echo -e "${GREEN}✅ Ollama started successfully${NC}"
        else
            echo -e "${RED}❌ Failed to start Ollama${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Ollama not installed. Please install with: brew install ollama${NC}"
        exit 1
    fi
}

# Function to check for models
check_models() {
    models=$(ollama list 2>/dev/null | grep -v "NAME" | wc -l | tr -d ' ')
    if [ "$models" -gt 0 ]; then
        echo -e "${GREEN}✅ Found $models model(s)${NC}"
        ollama list
    else
        echo -e "${YELLOW}⚠️  No models found${NC}"
        echo "Would you like to pull a recommended model? (llama3.2 - 2GB)"
        read -p "Pull llama3.2? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}📥 Pulling llama3.2...${NC}"
            ollama pull llama3.2
            echo -e "${GREEN}✅ Model pulled successfully${NC}"
        fi
    fi
}

# Function to check if Xcode is properly installed
check_xcode() {
    local has_xcode=false
    local has_cli_tools=false
    
    # Check if full Xcode is installed
    if [ -d "/Applications/Xcode.app" ]; then
        has_xcode=true
        echo -e "${GREEN}✅ Full Xcode is installed${NC}"
    else
        echo -e "${YELLOW}⚠️  Full Xcode not found in /Applications${NC}"
    fi
    
    # Check if command line tools are installed
    if xcode-select -p >/dev/null 2>&1; then
        has_cli_tools=true
        local dev_dir=$(xcode-select -p)
        echo -e "${GREEN}✅ Xcode Command Line Tools installed at: $dev_dir${NC}"
    else
        echo -e "${RED}❌ Xcode Command Line Tools not installed${NC}"
        echo "Install with: xcode-select --install"
        return 1
    fi
    
    # If we have full Xcode, ensure it's the active developer directory
    if [ "$has_xcode" = true ]; then
        local current_dev_dir=$(xcode-select -p 2>/dev/null)
        if [[ "$current_dev_dir" != "/Applications/Xcode.app/Contents/Developer" ]]; then
            echo -e "${YELLOW}🔧 Setting Xcode as active developer directory...${NC}"
            if sudo xcode-select -s /Applications/Xcode.app/Contents/Developer 2>/dev/null; then
                echo -e "${GREEN}✅ Developer directory updated${NC}"
            else
                echo -e "${YELLOW}⚠️  Could not update developer directory (permission issue)${NC}"
            fi
        fi
    fi
    
    # Check if xed command works (with error suppression)
    if command -v xed >/dev/null 2>&1; then
        # Test xed with a simple command that won't cause issues
        if xed --help >/dev/null 2>&1; then
            echo -e "${GREEN}✅ xed command is available and working${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  xed command exists but may not work properly${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  xed command not found${NC}"
    fi
    
    # If we reach here, xed isn't working properly
    if [ "$has_xcode" = true ]; then
        echo -e "${YELLOW}💡 Full Xcode is installed but xed command isn't working${NC}"
        echo -e "${YELLOW}   This usually happens when Xcode hasn't been launched yet${NC}"
        echo -e "${YELLOW}   or the developer directory needs to be reset${NC}"
    else
        echo -e "${YELLOW}💡 Only Command Line Tools detected${NC}"
        echo -e "${YELLOW}   For full Xcode features, install Xcode from the App Store${NC}"
    fi
    
    echo -e "${YELLOW}   Will use 'open' command as fallback${NC}"
    return 1
}

# Function to repair corrupted Xcode project
repair_xcode_project() {
    echo -e "${YELLOW}🔧 Attempting to repair corrupted Xcode project...${NC}"
    
    # Backup the corrupted project
    if [ -d "OllamaChat.xcodeproj" ]; then
        echo -e "${YELLOW}📦 Backing up corrupted project...${NC}"
        mv "OllamaChat.xcodeproj" "OllamaChat.xcodeproj.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Try to recreate the project structure
    echo -e "${YELLOW}🏗️  Recreating project structure...${NC}"
    mkdir -p "OllamaChat.xcodeproj/project.xcworkspace"
    
    # Create the workspace data file
    cat > "OllamaChat.xcodeproj/project.xcworkspace/contents.xcworkspacedata" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
EOF
    
    echo -e "${GREEN}✅ Project structure repaired${NC}"
    echo -e "${YELLOW}💡 You may need to re-add files to the project in Xcode${NC}"
    return 0
}

# Function to check if Xcode project is corrupted
check_project_health() {
    if [ ! -f "OllamaChat.xcodeproj/project.pbxproj" ]; then
        echo -e "${RED}❌ Project file missing${NC}"
        return 1
    fi
    
    # Try to parse the project file
    if ! plutil -lint "OllamaChat.xcodeproj/project.pbxproj" >/dev/null 2>&1; then
        echo -e "${RED}❌ Project file is corrupted or malformed${NC}"
        return 2
    fi
    
    echo -e "${GREEN}✅ Project file appears healthy${NC}"
    return 0
}

# Function to open Xcode project with fallback
open_xcode_project() {
    if check_xcode; then
        echo -e "${GREEN}📝 Opening with xed command...${NC}"
        xed OllamaChat.xcodeproj
    else
        echo -e "${YELLOW}📝 Opening with open command (fallback)...${NC}"
        if open OllamaChat.xcodeproj; then
            echo -e "${GREEN}✅ Project opened successfully${NC}"
        else
            echo -e "${RED}❌ Failed to open project${NC}"
            echo "Please try one of these options:"
            echo "1. Install full Xcode from App Store"
            echo "2. Double-click OllamaChat.xcodeproj in Finder"
            echo "3. Use command line build (option 2 or 3)"
            return 1
        fi
    fi
}

# Main execution
echo "🔍 Checking prerequisites..."

# Check if Ollama is installed
if ! command -v ollama >/dev/null 2>&1; then
    echo -e "${RED}❌ Ollama not found${NC}"
    echo "Install with: brew install ollama"
    exit 1
else
    echo -e "${GREEN}✅ Ollama is installed${NC}"
fi

# Check if Ollama is running
if ! check_ollama; then
    echo -e "${YELLOW}🔄 Ollama not running, attempting to start...${NC}"
    start_ollama
fi

# Check for models
echo "🔍 Checking for available models..."
check_models

# Check if Xcode project exists and is healthy
if [ ! -f "OllamaChat.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}❌ Xcode project not found in current directory${NC}"
    echo "Please run this script from the Application directory"
    exit 1
else
    echo "🔍 Checking project health..."
    if ! check_project_health; then
        echo -e "${YELLOW}⚠️  Project appears to be corrupted${NC}"
        read -p "Would you like to attempt repair? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            repair_xcode_project
        else
            echo -e "${RED}❌ Cannot proceed with corrupted project${NC}"
            exit 1
        fi
    fi
fi

echo -e "${GREEN}✅ All prerequisites met${NC}"
echo ""

# Ask what to do
echo "What would you like to do?"
echo "1) Build and run in Xcode"
echo "2) Build from command line (Debug)"
echo "3) Build from command line (Release)"
echo "4) Just open Xcode project"
echo "5) Show build information"
echo "6) Repair corrupted project"

read -p "Enter your choice (1-6): " choice

case $choice in
    1)
        echo -e "${GREEN}🚀 Opening Xcode and building...${NC}"
        open_xcode_project
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✨ You can now build and run from Xcode${NC}"
        fi
        ;;
    2)
        echo -e "${GREEN}🔨 Building Debug version...${NC}"
        if command -v make >/dev/null 2>&1; then
            make build
            echo -e "${GREEN}✅ Build complete! App location:${NC}"
            echo "build/Build/Products/Debug/OllamaChat.app"
        else
            echo -e "${YELLOW}⚠️  Make not found, using xcodebuild directly...${NC}"
            xcodebuild -project OllamaChat.xcodeproj -scheme OllamaChat -configuration Debug -derivedDataPath build clean build
            echo -e "${GREEN}✅ Build complete! Check build directory for output${NC}"
        fi
        ;;
    3)
        echo -e "${GREEN}🚀 Building Release version...${NC}"
        if command -v make >/dev/null 2>&1; then
            make release
            echo -e "${GREEN}✅ Build complete! App location:${NC}"
            echo "build/Build/Products/Release/OllamaChat.app"
        else
            echo -e "${YELLOW}⚠️  Make not found, using xcodebuild directly...${NC}"
            xcodebuild -project OllamaChat.xcodeproj -scheme OllamaChat -configuration Release -derivedDataPath build clean build
            echo -e "${GREEN}✅ Build complete! Check build directory for output${NC}"
        fi
        ;;
    4)
        echo -e "${GREEN}📝 Opening Xcode project...${NC}"
        open_xcode_project
        ;;
    5)
        echo -e "${GREEN}📊 Build Information${NC}"
        if command -v make >/dev/null 2>&1; then
            make info
        else
            echo -e "${GREEN}Project Information:${NC}"
            echo "Project: OllamaChat.xcodeproj"
            echo "Schemes: $(xcodebuild -project OllamaChat.xcodeproj -list | grep -A 10 'Schemes:' | tail -n +2 | head -10)"
            echo "Configurations: Debug, Release"
        fi
        ;;
    6)
        echo -e "${GREEN}🔧 Repairing project...${NC}"
        repair_xcode_project
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}🎉 Done!${NC}"
