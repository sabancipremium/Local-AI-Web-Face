import Foundation

print("🧪 Testing Ollama API connectivity...")

let semaphore = DispatchSemaphore(value: 0)

guard let url = URL(string: "http://localhost:11434/api/tags") else {
    print("❌ Invalid URL")
    exit(1)
}

let task = URLSession.shared.dataTask(with: url) { data, response, error in
    defer { semaphore.signal() }
    
    if let error = error {
        print("❌ Network error: \(error)")
        return
    }
    
    guard let httpResponse = response as? HTTPURLResponse else {
        print("❌ Invalid response")
        return
    }
    
    print("✅ HTTP Status: \(httpResponse.statusCode)")
    
    if httpResponse.statusCode == 200, let data = data {
        if let jsonString = String(data: data, encoding: .utf8) {
            print("✅ API Response received (first 200 chars):")
            print(String(jsonString.prefix(200)) + "...")
            
            // Parse to check for models
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let models = json?["models"] as? [[String: Any]] {
                    print("✅ Found \(models.count) models available:")
                    for model in models.prefix(3) {
                        if let name = model["name"] as? String {
                            print("  - \(name)")
                        }
                    }
                } else {
                    print("❌ No models found in response")
                }
            } catch {
                print("❌ JSON parsing error: \(error)")
            }
        }
    } else {
        print("❌ HTTP Status: \(httpResponse.statusCode)")
    }
}

task.resume()
semaphore.wait()

print("\n✅ Test completed!")
