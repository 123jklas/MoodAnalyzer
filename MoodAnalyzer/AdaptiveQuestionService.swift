import Foundation

struct AdaptiveQuestionService {
    let apiKey = "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" // Store securely, do not hardcode
    
    // Categories for adult mode
    let adultCategories = [
        "Resilience & Coping",
        "Mental Health & Mood",
        "Social Connection & Loneliness",
        "Satisfaction & Contentment",
        "Anxiety & Stress Management",
        "Mindfulness & Emotional Regulation",
        "Sleep & Physical Health",
        "Work-Life Balance"
    ]
    
    // Categories for child mode (green mode)
    let childCategories = [
        "Feeling Alone & Making Friends",
        "Happy Days & Contentment",
        "Staying Strong & Focused",
        "Feeling Blue & Sad Days",
        "Worry & Nervous Moments",
        "Bouncing Back & Finding Fun Solutions"
    ]
    
    // Anchor questions - one per category for adult mode (changed to statements for Likert responses)
    let adultAnchorQuestions: [String: Question] = [
        "Resilience & Coping": Question(text: "I can handle difficult situations well.", category: "Resilience & Coping", isReverseScored: false),
        "Mental Health & Mood": Question(text: "I generally feel positive about my life.", category: "Mental Health & Mood", isReverseScored: false),
        "Social Connection & Loneliness": Question(text: "I feel connected to others in my life.", category: "Social Connection & Loneliness", isReverseScored: false),
        "Satisfaction & Contentment": Question(text: "I am satisfied with my life right now.", category: "Satisfaction & Contentment", isReverseScored: false),
        "Anxiety & Stress Management": Question(text: "I can stay calm in stressful situations.", category: "Anxiety & Stress Management", isReverseScored: false),
        "Mindfulness & Emotional Regulation": Question(text: "I'm aware of my emotions as they happen.", category: "Mindfulness & Emotional Regulation", isReverseScored: false),
        "Sleep & Physical Health": Question(text: "I usually get enough rest and sleep well.", category: "Sleep & Physical Health", isReverseScored: false),
        "Work-Life Balance": Question(text: "I balance my work/study with personal time effectively.", category: "Work-Life Balance", isReverseScored: false)
    ]
    
    // Anchor questions for child mode (changed to statements for Likert responses)
    let childAnchorQuestions: [String: Question] = [
        "Feeling Alone & Making Friends": Question(text: "I feel good when I'm with other kids at school.", category: "Feeling Alone & Making Friends", isReverseScored: false),
        "Happy Days & Contentment": Question(text: "I have many things that make me happy during the day.", category: "Happy Days & Contentment", isReverseScored: false),
        "Staying Strong & Focused": Question(text: "I can keep trying even when things are hard.", category: "Staying Strong & Focused", isReverseScored: false),
        "Feeling Blue & Sad Days": Question(text: "I know what to do when I feel sad.", category: "Feeling Blue & Sad Days", isReverseScored: false),
        "Worry & Nervous Moments": Question(text: "I can handle feeling nervous or worried.", category: "Worry & Nervous Moments", isReverseScored: false),
        "Bouncing Back & Finding Fun Solutions": Question(text: "I can find good ways to fix problems when they happen.", category: "Bouncing Back & Finding Fun Solutions", isReverseScored: false)
    ]
    
    // Generate follow-up questions based on category and previous response
    func generateFollowUpQuestions(category: String, previousQuestion: String, response: String, isChildMode: Bool, completion: @escaping ([Question]?) -> Void) {
        let url = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create a prompt that's appropriate for the mode (adult or child)
        let prompt: String
        
        if isChildMode {
            prompt = """
            You are helping create follow-up questions for a child-friendly mental health assessment app. The child has just responded to a question about "\(category)".
            
            Previous question: "\(previousQuestion)"
            Child's response: "\(response)"
            
            Based on this response, generate 2 follow-up questions that:
            1. Are written in child-friendly language (ages 7-12)
            2. Explore the "\(category)" topic more deeply
            3. Are sensitive and supportive in tone
            4. Can be answered on a 5-point scale from "Strongly Agree" to "Strongly Disagree"
            5. Are not too leading or presumptive
            
            Return ONLY the questions in this exact format - one question per line, with no numbering, prefixes, or explanations:
            
            [question]I find it easy to make new friends at school.[/question][category]\(category)[/category][reverse]false[/reverse]
            [question]I sometimes feel left out when other kids are playing together.[/question][category]\(category)[/category][reverse]true[/reverse]
            
            The [reverse] tag should be "true" if a "Strongly Agree" would indicate a negative response (e.g., for questions about feeling sad, lonely, worried) and "false" otherwise.
            """
        } else {
            prompt = """
            You are helping create follow-up questions for a mental health assessment app. The user has just responded to a question about "\(category)".
            
            Previous question: "\(previousQuestion)"
            User's response: "\(response)"
            
            Based on this response, generate 2 follow-up questions that:
            1. Explore the "\(category)" topic more deeply
            2. Are sensitive and professionally worded
            3. Can be answered on a 5-point scale from "Strongly Agree" to "Strongly Disagree"
            4. Are not too leading or presumptive
            5. Would be appropriate in a clinical or therapeutic context
            
            Return ONLY the questions in this exact format - one question per line, with no numbering, prefixes, or explanations:
            
            [question]I am confident in my ability to handle unexpected challenges.[/question][category]\(category)[/category][reverse]false[/reverse]
            [question]I often feel overwhelmed when facing difficult situations.[/question][category]\(category)[/category][reverse]true[/reverse]
            
            The [reverse] tag should be "true" if a "Strongly Agree" would indicate a negative response (e.g., for questions about anxiety, depression, stress) and "false" otherwise.
            """
        }
        
        let body: [String: Any] = [
            "model": "llama-3.1-8b-instant",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 500,
            "top_p": 1.0
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    // Parse the generated questions
                    let questions = parseQuestions(from: content)
                    completion(questions)
                } else {
                    completion(nil)
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }
    
    // Parse the formatted questions from the LLM response
    private func parseQuestions(from content: String) -> [Question]? {
        var questions: [Question] = []
        
        // Define regex patterns to extract each component
        let questionPattern = "\\[question\\](.*?)\\[\\/question\\]"
        let categoryPattern = "\\[category\\](.*?)\\[\\/category\\]"
        let reversePattern = "\\[reverse\\](.*?)\\[\\/reverse\\]"
        
        // Split content by lines to process each question separately
        let lines = content.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        for line in lines {
            // Extract question text
            guard let questionRange = line.range(of: questionPattern, options: .regularExpression) else {
                continue
            }
            let questionMatch = line[questionRange]
            let questionText = extractContent(from: String(questionMatch), startTag: "[question]", endTag: "[/question]")
            
            // Extract category
            guard let categoryRange = line.range(of: categoryPattern, options: .regularExpression) else {
                continue
            }
            let categoryMatch = line[categoryRange]
            let category = extractContent(from: String(categoryMatch), startTag: "[category]", endTag: "[/category]")
            
            // Extract reverse scored flag
            guard let reverseRange = line.range(of: reversePattern, options: .regularExpression) else {
                continue
            }
            let reverseMatch = line[reverseRange]
            let reverseText = extractContent(from: String(reverseMatch), startTag: "[reverse]", endTag: "[/reverse]")
            let isReverseScored = reverseText.lowercased() == "true"
            
            // Create and add the question
            if !questionText.isEmpty && !category.isEmpty {
                let question = Question(text: questionText, category: category, isReverseScored: isReverseScored)
                questions.append(question)
            }
        }
        
        return questions.isEmpty ? nil : questions
    }
    
    // Helper function to extract content between tags
    private func extractContent(from string: String, startTag: String, endTag: String) -> String {
        guard let startRange = string.range(of: startTag),
              let endRange = string.range(of: endTag) else {
            return ""
        }
        
        let start = string.index(startRange.upperBound, offsetBy: 0)
        let end = endRange.lowerBound
        
        return String(string[start..<end])
    }
    
    // Get the initial anchor questions based on mode
    func getAnchorQuestions(isChildMode: Bool) -> [Question] {
        let questionDict = isChildMode ? childAnchorQuestions : adultAnchorQuestions
        return Array(questionDict.values)
    }
}
