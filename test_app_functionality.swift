#!/usr/bin/env swift

import Foundation

// Test the Ollama API directly to verify it works
func testOllamaAPI() async {
    guard let url = URL(string: "http://localhost:11434/api/tags") else {
        print("❌ Invalid URL")
        return
    }
    
    do {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("✅ HTTP Status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("✅ API Response received:")
                    print(String(jsonString.prefix(200)) + "...")
                    
                    // Parse to check for models
                    if let jsonData = jsonString.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                       let models = json["models"] as? [[String: Any]] {
                        print("✅ Found \(models.count) models available:")
                        for model in models.prefix(3) {
                            if let name = model["name"] as? String {
                                print("  - \(name)")
                            }
                        }
                    }
                } else {
                    print("❌ Could not decode response as UTF-8")
                }
            }
        }
    } catch {
        print("❌ Network request failed: \(error)")
    }
}

// Test a simple chat request
func testChatAPI() async {
    guard let url = URL(string: "http://localhost:11434/api/chat") else {
        print("❌ Invalid chat URL")
        return
    }
    
    let chatRequest = [
        "model": "llama3.2:latest",
        "messages": [
            ["role": "user", "content": "Say 'Test successful' if you can hear me"]
        ],
        "stream": false
    ] as [String : Any]
    
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: chatRequest)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("✅ Chat API Status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                if let jsonString = String(data: data, encoding: .utf8),
                   let jsonData = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let message = json["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    print("✅ Chat Response: \(content)")
                } else {
                    print("❌ Could not parse chat response")
                }
            }
        }
    } catch {
        print("❌ Chat request failed: \(error)")
    }
}

// Main test function
func runTests() async {
    print("🧪 Testing Local-AI-Web-Face App Functionality")
    print(String(repeating: "=", count: 50))
    
    print("\n📡 Testing Ollama API connectivity...")
    await testOllamaAPI()
    
    print("\n💬 Testing chat functionality...")
    await testChatAPI()
    
    print("\n✅ Tests completed!")
}

// Run the tests
await runTests()
