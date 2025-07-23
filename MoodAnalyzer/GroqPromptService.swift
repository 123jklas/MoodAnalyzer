import Foundation

struct GroqPromptService {
    let apiKey = "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" // Store securely, do not hardcode
    
    // Generate initial drawing prompt
    func generateInitialPrompt(completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        Generate a therapeutic drawing prompt that would be appropriate for an emotional assessment. The prompt should:
        1. Encourage creative expression
        2. Be open-ended but specific enough to be actionable
        3. Allow for emotional expression without being too intrusive
        4. Be suitable for both teenagers and adults
        5. Ask the person to draw something that represents their current emotional state

        The prompt should be 2-3 sentences long and encouraging in tone. Do not include any explanation or commentary - just provide the drawing prompt itself.
        """
        
        let body: [String: Any] = [
            "model": "llama-3.1-8b-instant",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 200,
            "top_p": 1.0
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion("Error: \(error.localizedDescription)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(content.trimmingCharacters(in: .whitespacesAndNewlines))
                } else {
                    completion("Error: Unable to parse response")
                }
            } catch {
                completion("Error parsing JSON: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    // Generate next prompt based on previous drawing analysis
    func generateNextPrompt(iteration: Int, previousAnalysis: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Ensure we're using the correct prompt number
        let promptNumber = iteration
        let promptTotal = 3
        
        // Create a prompt that builds on the previous analysis
        let prompt = """
        Here is an analysis of a person's drawing:
        
        \(previousAnalysis)
        
        Based on this analysis, I need you to generate the next therapeutic drawing prompt (Prompt #\(promptNumber) of \(promptTotal)). The prompt should:
        
        1. Build upon insights from the previous drawing analysis
        2. Explore a different aspect of their emotional expression
        3. Be constructive and supportive in tone
        4. Be specific enough to guide their drawing but open enough for personal expression
        5. Avoid being overly clinical or diagnostic in wording
        
        If this is prompt #2 (of 3), focus on feelings of safety, security or social connection.
        If this is prompt #3 (of 3), focus on future aspirations, hopes, or desired emotional states.
        
        The prompt should be 2-3 sentences long. Do not include any explanation or commentary - just provide the drawing prompt itself. Do not include "Prompt #2 of 3:" or similar text in your response.
        """
        
        let body: [String: Any] = [
            "model": "llama-3.1-8b-instant",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 200,
            "top_p": 1.0
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion("Error: \(error.localizedDescription)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    // Remove any "Prompt #X of 3:" prefix if it exists despite our instructions
                    let cleanedContent = removePromptPrefix(from: content)
                    completion(cleanedContent.trimmingCharacters(in: .whitespacesAndNewlines))
                } else {
                    completion("Error: Unable to parse response")
                }
            } catch {
                completion("Error parsing JSON: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    // Helper function to remove prompt numbering prefixes
    private func removePromptPrefix(from content: String) -> String {
        // Regular expression to match patterns like "Prompt #X of Y:" or "Prompt #X:"
        let pattern = "^(Prompt\\s+#\\d+\\s+of\\s+\\d+:\\s*)|(Prompt\\s+#\\d+:\\s*)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
            let range = NSRange(location: 0, length: content.utf16.count)
            return regex.stringByReplacingMatches(in: content, options: [], range: range, withTemplate: "")
        }
        return content
    }
    
    // Generate final cumulative analysis based on all drawing analyses
    func generateCumulativeAnalysis(analyses: [String], completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Join all analyses with clear separation
        let analysisTexts = analyses.enumerated().map { index, analysis in
            return "Drawing \(index + 1) Analysis:\n\(analysis)"
        }.joined(separator: "\n\n----------\n\n")
        
        let prompt = """
        I have conducted a series of 3 guided drawing exercises with therapeutic prompts, and analyzed each drawing. Here are the analyses:
        
        \(analysisTexts)
        
        Based on these three drawing analyses, create a comprehensive therapeutic assessment report that:
        
        1. Identifies patterns and evolution across the three drawings
        2. Highlights strengths and positive aspects observed
        3. Notes any areas that might benefit from support or exploration
        4. Provides an integrated understanding of the emotional expression shown across all drawings
        5. Includes a section on emotional metrics similar to what would be found in a therapeutic report
        
        Format the report professionally with clear sections, but maintain a supportive and non-clinical tone. The report should be comprehensive but concise, approximately 400-600 words.
        """
        
        let body: [String: Any] = [
            "model": "llama-3.1-8b-instant",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 1024,
            "top_p": 1.0
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion("Error: \(error.localizedDescription)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(content)
                } else {
                    completion("Error: Unable to parse response")
                }
            } catch {
                completion("Error parsing JSON: \(error.localizedDescription)")
            }
        }.resume()
    }
}
