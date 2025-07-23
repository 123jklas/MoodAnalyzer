import SwiftUI

// MainQuestionsView is the main flow (questions, results, drawing) that uses the chosen mode.
struct MainQuestionsView: View {
    let isGreenMode: Bool
    
    // State variables for question flow
    @State private var currentQuestionIndex = 0
    @State private var responses: [(question: Question, score: Int)] = []
    @State private var showResultsView = false
    @State private var isGeneratingQuestions = false
    @State private var currentCategory = ""
    
    // Track which categories have been covered
    @State private var remainingCategories: [String] = []
    @State private var currentQuestions: [Question] = []
    @State private var questionsPerCategory = 3 // Anchor + 2 follow-ups
    @State private var questionsAskedInCurrentCategory = 0
    
    // For tracking anchor questions
    @State private var currentAnchorQuestion: Question? = nil
    @State private var lastAnchorResponse = ""
    
    // Service for adaptive questioning
    let adaptiveQuestionService = AdaptiveQuestionService()
    
    // Progress calculation
    var totalCategories: Int {
        isGreenMode ? adaptiveQuestionService.childCategories.count : adaptiveQuestionService.adultCategories.count
    }
    
    var completedCategories: Int {
        totalCategories - remainingCategories.count
    }
    
    var progress: Double {
        // Categories completed + progress within current category
        let categoriesProgress = Double(completedCategories)
        let currentCategoryProgress = Double(questionsAskedInCurrentCategory) / Double(questionsPerCategory)
        return (categoriesProgress + (currentCategoryProgress * (questionsAskedInCurrentCategory > 0 ? 1 : 0))) / Double(totalCategories)
    }
    
    // Likert scale options.
    let likertOptions = ["Strongly Agree", "Agree", "Unsure", "Disagree", "Strongly Disagree"]
    
    // Mapping Likert responses to numeric scores.
    let scoreMapping: [String: Int] = [
        "Strongly Agree": 5,
        "Agree": 4,
        "Unsure": 3,
        "Disagree": 2,
        "Strongly Disagree": 1
    ]
    
    // Text responses for anchor questions based on Likert choice
    let likertTextResponses: [String: String] = [
        "Strongly Agree": "I strongly agree with this statement. This resonates very much with my experience.",
        "Agree": "I agree with this statement. This generally matches my experience.",
        "Unsure": "I'm uncertain about this statement. I have mixed feelings about this.",
        "Disagree": "I disagree with this statement. This doesn't match my experience much.",
        "Strongly Disagree": "I strongly disagree with this statement. This doesn't reflect my experience at all."
    ]
    
    var body: some View {
        VStack {
            Text("Mode: \(isGreenMode ? "Green Mode" : "Regular Mode")")
                .font(.caption)
                .foregroundColor(.gray)
            
            if showResultsView {
                ResultsView(responses: responses, isGreenMode: isGreenMode)
            } else {
                // Progress Bar for completed categories and questions
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 200)
                    .padding()
                
                Text("\(Int(progress * 100))% completed")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if isGeneratingQuestions {
                    // Loading indicator when generating questions
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                        Text("Generating personalized questions...")
                            .font(.headline)
                    }
                } else if !currentQuestions.isEmpty {
                    // Display current follow-up question with Likert scale
                    let currentQuestion = currentQuestions[0]
                    
                    VStack(alignment: .leading, spacing: 10) {
                        if questionsAskedInCurrentCategory > 0 {
                            Text(currentCategory)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .padding(.horizontal)
                        }
                        
                        Text(currentQuestion.text)
                            .font(.title2)
                            .padding()
                    }
                    
                    ForEach(likertOptions, id: \.self) { option in
                        Button(action: {
                            if let score = scoreMapping[option] {
                                let finalScore = currentQuestion.isReverseScored ? (6 - score) : score
                                responses.append((question: currentQuestion, score: finalScore))
                                moveToNextQuestion()
                            }
                        }) {
                            Text(option)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                } else if currentAnchorQuestion != nil {
                    // Display anchor question with Likert scale (same as follow-up questions)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(currentCategory)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.horizontal)
                        
                        Text(currentAnchorQuestion?.text ?? "")
                            .font(.title2)
                            .padding()
                    }
                    
                    ForEach(likertOptions, id: \.self) { option in
                        Button(action: {
                            handleAnchorResponse(option)
                        }) {
                            Text(option)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                } else {
                    // Initial state or when moving to a new category
                    VStack {
                        Text("Ready to continue?")
                            .font(.headline)
                        
                        Button("Start") {
                            loadNextCategory()
                        }
                        .padding()
                        .frame(width: 200)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                }
            }
        }
        .padding()
        .onAppear {
            // Initialize categories when view appears
            initializeCategories()
        }
    }
    
    // Initialize the list of categories based on the selected mode
    private func initializeCategories() {
        if isGreenMode {
            remainingCategories = adaptiveQuestionService.childCategories
        } else {
            remainingCategories = adaptiveQuestionService.adultCategories
        }
    }
    
    // Load the next category and its anchor question
    private func loadNextCategory() {
        guard !remainingCategories.isEmpty else {
            // All categories completed
            showResultsView = true
            return
        }
        
        // Reset counters for new category
        questionsAskedInCurrentCategory = 0
        
        // Get the next category
        currentCategory = remainingCategories.removeFirst()
        
        // Get the anchor question for this category
        if isGreenMode {
            currentAnchorQuestion = adaptiveQuestionService.childAnchorQuestions[currentCategory]
        } else {
            currentAnchorQuestion = adaptiveQuestionService.adultAnchorQuestions[currentCategory]
        }
        
        // If no anchor question is found, move to next category
        if currentAnchorQuestion == nil {
            moveToNextCategory()
        }
    }
    
    // Handle Likert response to anchor question
    private func handleAnchorResponse(_ option: String) {
        guard let anchorQuestion = currentAnchorQuestion else {
            return
        }
        
        // Store the score for the anchor question
        if let score = scoreMapping[option] {
            let finalScore = anchorQuestion.isReverseScored ? (6 - score) : score
            responses.append((question: anchorQuestion, score: finalScore))
        }
        
        questionsAskedInCurrentCategory += 1
        
        // Get text expansion of the Likert choice to use for generating follow-up questions
        lastAnchorResponse = likertTextResponses[option] ?? "I selected \(option)."
        
        // Generate follow-up questions based on their response
        isGeneratingQuestions = true
        currentAnchorQuestion = nil
        
        adaptiveQuestionService.generateFollowUpQuestions(
            category: currentCategory,
            previousQuestion: anchorQuestion.text,
            response: lastAnchorResponse,
            isChildMode: isGreenMode
        ) { generatedQuestions in
            DispatchQueue.main.async {
                isGeneratingQuestions = false
                
                if let questions = generatedQuestions, !questions.isEmpty {
                    currentQuestions = questions
                } else {
                    // If generation fails, move to next category
                    moveToNextCategory()
                }
            }
        }
    }
    
    // Move to the next question or category
    private func moveToNextQuestion() {
        questionsAskedInCurrentCategory += 1
        
        // Remove the question we just answered
        if !currentQuestions.isEmpty {
            currentQuestions.removeFirst()
        }
        
        // Check if we've reached the target number of questions for this category
        if questionsAskedInCurrentCategory >= questionsPerCategory || currentQuestions.isEmpty {
            moveToNextCategory()
        }
    }
    
    // Move to the next category
    private func moveToNextCategory() {
        currentQuestions = []
        currentAnchorQuestion = nil
        
        if remainingCategories.isEmpty {
            // All categories completed
            showResultsView = true
        } else {
            // Load the next category
            loadNextCategory()
        }
    }
}
