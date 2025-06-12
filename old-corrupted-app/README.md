# Ollama Chat - macOS AI Assistant

A beautiful, native macOS application for chatting with local AI models using Ollama.

## Features

### Core Features
- 🤖 **Local AI Chat**: Communicate with AI models running locally via Ollama
- 🔄 **Model Management**: Switch between different AI models seamlessly  
- 🎙️ **Text-to-Speech**: Built-in TTS with customizable voices and speech rate
- 💾 **Chat History**: Persistent conversation history
- ⚙️ **Settings**: Comprehensive configuration options
- 🔌 **Connection Monitoring**: Real-time Ollama server status

### User Interface
- 🎨 **Native macOS Design**: Built with SwiftUI for a native feel
- 📱 **Responsive Layout**: Adaptive interface that works on different screen sizes
- 🌗 **System Appearance**: Supports light and dark mode
- ⌨️ **Keyboard Shortcuts**: Quick actions and navigation
- 📋 **Export Functionality**: Export chat conversations

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later (for building)
- [Ollama](https://ollama.ai) installed and running

## Installation

### Option 1: Download Pre-built App
1. Download the latest release from the releases page
2. Move `OllamaChat.app` to your Applications folder
3. Launch the app

### Option 2: Build from Source
1. Clone this repository
2. Open `OllamaChat.xcodeproj` in Xcode
3. Build and run the project

## Setup

### 1. Install Ollama
```bash
# Using Homebrew
brew install ollama

# Or download from https://ollama.ai
```

### 2. Start Ollama Service
```bash
ollama serve
```

### 3. Pull AI Models
```bash
# Recommended models
ollama pull llama3.2        # Fast, general-purpose (2GB)
ollama pull codellama       # Code generation (3.8GB)
ollama pull mistral         # High-quality text (4.1GB)
ollama pull phi3            # Efficient model (2.3GB)
```

### 4. Verify Installation
```bash
ollama list
```

## Usage

1. **Launch the App**: Open OllamaChat from your Applications folder
2. **Select Model**: Choose an AI model from the sidebar
3. **Start Chatting**: Type your message and press Enter or click Send
4. **Configure TTS**: Enable text-to-speech in Settings for audio responses
5. **Manage Models**: Use Settings to view and manage installed models

## Configuration

### Server Settings
- **Server URL**: Default is `http://localhost:11434`
- **Connection Test**: Verify connectivity to Ollama server
- **Default Model**: Set your preferred model for new chats

### Text-to-Speech
- **Enable/Disable**: Toggle TTS functionality
- **Voice Selection**: Choose from available system voices
- **Speech Rate**: Adjust speaking speed (10% - 100%)
- **Voice Test**: Preview selected voice settings

## Architecture

The application follows a clean MVVM architecture with SwiftUI:

### Core Components
- **OllamaChatApp**: Main application entry point
- **ContentView**: Primary interface with sidebar and chat area
- **ChatView**: Message display and input handling
- **SettingsView**: Configuration interface

### Services
- **OllamaService**: HTTP API communication with Ollama
- **ModelManager**: Model discovery and management
- **TTSManager**: Text-to-speech functionality

### Models
- **ChatMessage**: Message data structure
- **OllamaResponse**: API response models

## API Integration

The app communicates with Ollama through its REST API:

### Endpoints Used
- `GET /api/tags` - List available models
- `POST /api/chat` - Send chat messages
- Connection testing and health checks

### Message Format
```json
{
  "model": "llama3.2",
  "messages": [
    {"role": "user", "content": "Hello!"},
    {"role": "assistant", "content": "Hi there!"}
  ],
  "stream": false
}
```

## Troubleshooting

### Common Issues

**App shows "No models found"**
- Ensure Ollama is installed: `brew install ollama`
- Start Ollama service: `ollama serve`
- Pull at least one model: `ollama pull llama3.2`

**Connection failed**
- Check if Ollama is running: `ollama list`
- Verify server URL in Settings (default: `http://localhost:11434`)
- Check firewall settings

**TTS not working**
- Verify TTS is enabled in Settings
- Check system voice availability
- Try different voice selection

**Performance issues**
- Close other resource-intensive applications
- Use smaller models (phi3, llama3.2)
- Monitor system resources

## Development

### Project Structure
```
OllamaChat/
├── OllamaChatApp.swift          # App entry point
├── Views/
│   ├── ContentView.swift        # Main interface
│   ├── ChatView.swift          # Chat interface
│   └── SettingsView.swift      # Settings interface
├── Services/
│   ├── OllamaService.swift     # API communication
│   ├── ModelManager.swift      # Model management
│   └── TTSManager.swift        # Text-to-speech
├── Models/
│   └── ChatMessage.swift       # Data models
└── Assets.xcassets/            # App resources
```

### Building
1. Open `OllamaChat.xcodeproj` in Xcode
2. Select your target device/simulator
3. Build and run (⌘+R)

### Testing
- Unit tests for services and models
- UI tests for critical user flows
- Integration tests with Ollama API

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Ollama](https://ollama.ai) for the excellent local AI platform
- Apple for SwiftUI and macOS development tools
- The open-source AI community for model development

## Support

- 📖 Check the documentation in this README
- 🐛 Report bugs through GitHub Issues
- 💡 Request features through GitHub Issues
- 📧 Contact: [Your email/contact]

---

**Note**: This application requires Ollama to be installed and running. It provides a user-friendly interface for interacting with local AI models without requiring technical knowledge of command-line tools.
