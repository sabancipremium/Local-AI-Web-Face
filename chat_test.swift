import Foundation

print("💬 Testing Ollama Chat API...")

let semaphore = DispatchSemaphore(value: 0)

guard let url = URL(string: "http://localhost:11434/api/chat") else {
    print("❌ Invalid URL")
    exit(1)
}

let chatRequest: [String: Any] = [
    "model": "llama3.2:latest",
    "messages": [
        ["role": "user", "content": "Reply with exactly: 'Test OK'"]
    ],
    "stream": false
]

do {
    let jsonData = try JSONSerialization.data(withJSONObject: chatRequest)
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        defer { semaphore.signal() }
        
        if let error = error {
            print("❌ Network error: \(error)")
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response")
            return
        }
        
        print("✅ Chat API Status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 200, let data = data {
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let message = json?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    print("✅ Chat Response: \(content)")
                    print("✅ Chat functionality verified!")
                } else {
                    print("❌ Could not parse chat response")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Raw response: \(String(jsonString.prefix(200)))")
                    }
                }
            } catch {
                print("❌ JSON parsing error: \(error)")
            }
        } else {
            print("❌ HTTP Status: \(httpResponse.statusCode)")
        }
    }
    
    task.resume()
    semaphore.wait()
    
} catch {
    print("❌ JSON serialization error: \(error)")
}

print("\n✅ Chat test completed!")
