#!/bin/bash

# Development Debug Script for Local-AI-Web-Face
# This script helps debug the app with comprehensive logging

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 Local-AI-Web-Face Debug Launcher${NC}"
echo "========================================="

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
    echo -e "${BLUE}📋 Checking available models...${NC}"
    models=$(curl -s http://localhost:11434/api/tags | jq -r '.models[]?.name // empty' 2>/dev/null | wc -l | tr -d ' ')
    if [ "$models" -gt 0 ]; then
        echo -e "${GREEN}✅ Found $models model(s)${NC}"
        echo "Available models:"
        curl -s http://localhost:11434/api/tags | jq -r '.models[]?.name // empty' 2>/dev/null | sed 's/^/  - /'
    else
        echo -e "${YELLOW}⚠️  No models found. You may need to pull a model first:${NC}"
        echo "  ollama pull llama3.2"
        echo "  ollama pull qwen2.5:0.5b"
    fi
}

# Function to test Ollama API directly
test_ollama_api() {
    echo -e "${BLUE}🧪 Testing Ollama API directly...${NC}"
    
    # Test basic connection
    echo "Testing /api/tags endpoint:"
    curl -s http://localhost:11434/api/tags | jq '.' || echo "Failed to get tags"
    
    # Test chat endpoint if models exist
    local first_model=$(curl -s http://localhost:11434/api/tags | jq -r '.models[0]?.name // empty' 2>/dev/null)
    if [ -n "$first_model" ]; then
        echo -e "\nTesting chat endpoint with model: $first_model"
        echo '{"model":"'$first_model'","messages":[{"role":"user","content":"Hello"}],"stream":false}' | \
        curl -s -X POST http://localhost:11434/api/chat \
            -H "Content-Type: application/json" \
            -d @- | jq '.' || echo "Chat test failed"
    fi
}

# Function to build and run the app with logging
build_and_run() {
    echo -e "${BLUE}🔨 Building the app...${NC}"
    
    cd "/Users/mchalil/Documents/XCode Projects/Local-AI-Web-Face"
    
    # Clean and build
    xcodebuild -project Local-AI-Web-Face.xcodeproj -scheme Local-AI-Web-Face clean build
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Build successful${NC}"
        
        echo -e "${BLUE}🚀 Launching app with debug logging...${NC}"
        echo -e "${YELLOW}📝 Console logs will show detailed debugging information${NC}"
        echo -e "${YELLOW}   Watch for [ChatViewModel], [ChatMessage], and [OllamaService] logs${NC}"
        echo ""
        
        # Launch the app
        open "/Users/mchalil/Library/Developer/Xcode/DerivedData/Local-AI-Web-Face-cebbdlcksakzvpdnpsaxogcwopgr/Build/Products/Debug/Local-AI-Web-Face.app"
        
        echo -e "${BLUE}📊 Monitoring app logs...${NC}"
        echo "To see live logs, run in another terminal:"
        echo "  log stream --predicate 'process == \"Local-AI-Web-Face\"' --info --debug"
        echo ""
        echo "Or check Console.app and filter for 'Local-AI-Web-Face'"
        
    else
        echo -e "${RED}❌ Build failed${NC}"
        exit 1
    fi
}

# Function to show live logs
show_logs() {
    echo -e "${BLUE}📊 Showing live application logs...${NC}"
    echo "Press Ctrl+C to stop"
    echo ""
    log stream --predicate 'process == "Local-AI-Web-Face"' --info --debug
}

# Function to test specific chat functionality
test_chat() {
    echo -e "${BLUE}🗨️  Testing chat functionality...${NC}"
    
    # Get first available model
    local model=$(curl -s http://localhost:11434/api/tags | jq -r '.models[0]?.name // empty' 2>/dev/null)
    if [ -z "$model" ]; then
        echo -e "${RED}❌ No models available for testing${NC}"
        return 1
    fi
    
    echo "Testing streaming chat with model: $model"
    
    # Test streaming chat
    echo '{"model":"'$model'","messages":[{"role":"user","content":"Hello, can you count to 5?"}],"stream":true}' | \
    curl -s -X POST http://localhost:11434/api/chat \
        -H "Content-Type: application/json" \
        -d @- | head -10
}

# Main menu
show_menu() {
    echo ""
    echo -e "${BLUE}Debug Options:${NC}"
    echo "1. Check Ollama status and start if needed"
    echo "2. Check available models"
    echo "3. Test Ollama API directly"
    echo "4. Test chat functionality"
    echo "5. Build and run app with debug logging"
    echo "6. Show live app logs"
    echo "7. Run all checks and launch app"
    echo "8. Exit"
    echo ""
}

# Parse command line arguments
case "${1:-menu}" in
    "check")
        check_ollama && check_models
        ;;
    "start")
        check_ollama || start_ollama
        check_models
        ;;
    "test")
        check_ollama && test_ollama_api && test_chat
        ;;
    "build")
        build_and_run
        ;;
    "logs")
        show_logs
        ;;
    "all")
        check_ollama || start_ollama
        check_models
        test_ollama_api
        build_and_run
        ;;
    "menu"|*)
        while true; do
            show_menu
            read -p "Choose an option (1-8): " choice
            case $choice in
                1)
                    check_ollama || start_ollama
                    ;;
                2)
                    check_models
                    ;;
                3)
                    test_ollama_api
                    ;;
                4)
                    test_chat
                    ;;
                5)
                    build_and_run
                    ;;
                6)
                    show_logs
                    ;;
                7)
                    check_ollama || start_ollama
                    check_models
                    test_ollama_api
                    build_and_run
                    ;;
                8)
                    echo -e "${GREEN}👋 Goodbye!${NC}"
                    exit 0
                    ;;
                *)
                    echo -e "${RED}Invalid option. Please choose 1-8.${NC}"
                    ;;
            esac
            echo ""
            read -p "Press Enter to continue..."
        done
        ;;
esac
