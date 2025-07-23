import SwiftUI
import PencilKit

struct DrawingOnlyView: View {
    // State variables to manage the flow
    @State private var currentIteration = 1
    @State private var maxIterations = 3
    @State private var canvasView = PKCanvasView()
    @State private var selectedColor: UIColor = .black
    @State private var isAnalyzing = false
    @State private var isGeneratingPrompt = false
    @State private var isGeneratingFinalReport = false
    @State private var currentPrompt = ""
    @State private var drawingAnalyses = [String]()
    @State private var drawingImages = [UIImage]()
    @State private var drawingPrompts = [String]()
    @State private var showAnalysisView = false
    @State private var showFinalReport = false
    @State private var analysisToShow = ""
    @State private var allAnalysesCompleted = false
    @State private var cumulativeAnalysis = ""
    
    // Define a palette of colors for the user to choose from
    let palette: [UIColor] = [.black, .red, .green, .blue, .orange, .purple, .brown, .yellow]
    
    var body: some View {
        VStack {
            // Progress indicator
            HStack {
                ForEach(1...maxIterations, id: \.self) { iteration in
                    Circle()
                        .fill(iteration <= currentIteration ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 15, height: 15)
                }
            }
            .padding(.top)
            
            // Current prompt section
            VStack(alignment: .leading, spacing: 10) {
                Text("Drawing Prompt")
                    .font(.headline)
                
                if isGeneratingPrompt {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Generating prompt...")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.systemGray6))
                    )
                } else if !currentPrompt.isEmpty {
                    // Use ScrollView to allow the prompt to scroll if it's too long
                    ScrollView {
                        Text(currentPrompt)
                            .padding()
                    }
                    .frame(height: 100) // Fixed height container for scroll view
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    )
                } else {
                    Button(action: {
                        self.generateInitialPrompt()
                    }) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("Generate First Prompt")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal)
            
            // Drawing canvas
            DrawingCanvas(canvasView: $canvasView, selectedColor: selectedColor)
                .frame(height: 400)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                .padding()
            
            // Color palette selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(palette, id: \.self) { color in
                        Circle()
                            .fill(Color(color))
                            .frame(width: 40, height: 40)
                            .onTapGesture {
                                selectedColor = color
                            }
                            .overlay(
                                Circle()
                                    .stroke(selectedColor == color ? Color.gray : Color.clear, lineWidth: 2)
                            )
                    }
                }
                .padding(.horizontal)
            }
            
            // Action buttons
            HStack(spacing: 20) {
                Button(action: {
                    // Clear the canvas
                    canvasView.drawing = PKDrawing()
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear")
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    analyzeCurrentDrawing()
                }) {
                    HStack {
                        if isAnalyzing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "checkmark.circle")
                            Text("Submit Drawing")
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(isAnalyzing ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isAnalyzing || currentPrompt.isEmpty)
            }
            .padding(.top, 10)
            
            // Fixed layout for previous analyses and final report buttons
            VStack(spacing: 15) {
                // Previous analyses button row
                if !drawingAnalyses.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(0..<drawingAnalyses.count, id: \.self) { index in
                                Button(action: {
                                    analysisToShow = drawingAnalyses[index]
                                    showAnalysisView = true
                                }) {
                                    HStack {
                                        Image(systemName: "doc.text.magnifyingglass")
                                        Text("Analysis \(index + 1)")
                                    }
                                    .padding(8)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(5)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Final report button in its own row when all analyses are complete
                if allAnalysesCompleted {
                    Button(action: {
                        if cumulativeAnalysis.isEmpty {
                            generateCumulativeAnalysis { analysis in
                                self.cumulativeAnalysis = analysis
                                self.showFinalReport = true
                            }
                        } else {
                            showFinalReport = true
                        }
                    }) {
                        HStack {
                            if isGeneratingFinalReport {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Generating Final Report...")
                            } else {
                                Image(systemName: "doc.text.fill")
                                Text("View Final Report")
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity) // Make button full width
                        .background(isGeneratingFinalReport ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(isGeneratingFinalReport)
                    .padding(.horizontal)
                }
            }
            .padding(.top, 5)
        }
        .padding(.bottom)
        .navigationTitle("Drawing Expression")
        .sheet(isPresented: $showAnalysisView) {
            AnalysisView(analysisText: analysisToShow)
        }
        .fullScreenCover(isPresented: $showFinalReport) {
            FinalReportView(
                responses: [], // No questionnaire responses in drawing-only mode
                drawingAnalysis: cumulativeAnalysis.isEmpty ? generatePlaceholderAnalysis() : cumulativeAnalysis,
                drawingImage: drawingImages.last ?? UIImage(),
                isGreenMode: false,
                allDrawings: drawingImages,
                allAnalyses: drawingAnalyses,
                drawingPrompts: getDrawingPrompts()
            )
        }
        .alert(isPresented: Binding<Bool>(
            get: { currentIteration > maxIterations && !showFinalReport && !allAnalysesCompleted },
            set: { _ in }
        )) {
            Alert(
                title: Text("Drawing Session Complete"),
                message: Text("All \(maxIterations) drawing iterations are complete. View your final report?"),
                primaryButton: .default(Text("View Report")) {
                    allAnalysesCompleted = true
                    generateCumulativeAnalysis { analysis in
                        self.cumulativeAnalysis = analysis
                        self.showFinalReport = true
                    }
                },
                secondaryButton: .cancel(Text("Later")) {
                    allAnalysesCompleted = true
                }
            )
        }
        .onAppear {
            // Check if we already have all analyses
            if drawingAnalyses.count >= maxIterations {
                allAnalysesCompleted = true
            }
        }
    }
    
    func generateInitialPrompt() {
        isGeneratingPrompt = true
        
        // Call the Groq service to generate the first prompt
        GroqPromptService().generateInitialPrompt { result in
            DispatchQueue.main.async {
                if let prompt = result {
                    currentPrompt = prompt
                } else {
                    // Fallback prompt in case of API failure
                    currentPrompt = "Draw a tree that represents how you feel today. It can be any kind of tree in any setting or season that best captures your current emotional state."
                }
                isGeneratingPrompt = false
            }
        }
    }
    
    private func analyzeCurrentDrawing() {
        // First, capture the drawing
        guard !canvasView.drawing.bounds.isEmpty else {
            // Alert the user that the drawing is empty
            return
        }
        
        isAnalyzing = true
        
        // Capture the current drawing
        let image = canvasView.drawing.image(from: canvasView.bounds, scale: 1.0)
        
        // Call the vision API to analyze the drawing
        GroqVisionAPI().analyzeDrawing(image: image) { response in
            DispatchQueue.main.async {
                if let analysisText = response {
                    // Store the analysis, image, and prompt
                    drawingAnalyses.append(analysisText)
                    drawingImages.append(image)
                    drawingPrompts.append(currentPrompt)
                    
                    // Show the analysis
                    analysisToShow = analysisText
                    showAnalysisView = true
                    
                    // Move to next iteration or finalize
                    handleNextIteration(previousAnalysis: analysisText)
                } else {
                    // Handle error
                    print("Error in drawing analysis")
                }
                
                isAnalyzing = false
            }
        }
    }
    
    private func handleNextIteration(previousAnalysis: String) {
        currentIteration += 1
        
        // Clear canvas for next drawing
        canvasView.drawing = PKDrawing()
        
        if currentIteration <= maxIterations {
            // Generate the next prompt based on the previous analysis
            generateNextPrompt(basedOn: previousAnalysis)
        } else {
            // All iterations completed
            allAnalysesCompleted = true
        }
    }
    
    private func generateNextPrompt(basedOn analysis: String) {
        isGeneratingPrompt = true
        
        // Call the Groq service to generate the next prompt based on analysis
        GroqPromptService().generateNextPrompt(iteration: currentIteration, previousAnalysis: analysis) { result in
            DispatchQueue.main.async {
                if let prompt = result {
                    currentPrompt = prompt
                } else {
                    // Fallback prompts in case of API failure
                    if currentIteration == 2 {
                        currentPrompt = "Now, draw a scene that represents a safe place for you - somewhere you feel comfortable and secure. This can be a real or imaginary place."
                    } else if currentIteration == 3 {
                        currentPrompt = "For your final drawing, create an image that shows how you hope to feel in the future. What does your ideal emotional state look like?"
                    }
                }
                isGeneratingPrompt = false
            }
        }
    }
    
    // Helper method to get all prompts used in the session
    private func getDrawingPrompts() -> [String] {
        return drawingPrompts
    }
    
    // Use the GroqPromptService to generate the cumulative analysis with a callback
    private func generateCumulativeAnalysis(completion: @escaping (String) -> Void) {
        // Check if we have all analyses
        guard drawingAnalyses.count >= maxIterations else {
            completion(generatePlaceholderAnalysis())
            return
        }
        
        isGeneratingFinalReport = true
        
        // Call the Groq service to generate the cumulative analysis
        GroqPromptService().generateCumulativeAnalysis(analyses: drawingAnalyses) { result in
            DispatchQueue.main.async {
                self.isGeneratingFinalReport = false
                
                if let analysis = result {
                    completion(analysis)
                } else {
                    // Fallback to a template if API fails
                    completion(self.generatePlaceholderAnalysis())
                }
            }
        }
    }
    
    // Generate a placeholder analysis in case the API call fails
    private func generatePlaceholderAnalysis() -> String {
        return """
        ## Comprehensive Emotional Expression Analysis
        
        Based on the series of guided drawing exercises, we've assembled a holistic view of your emotional expression patterns.
        
        ### Drawing 1: Current Emotional State
        \(drawingAnalyses.indices.contains(0) ? drawingAnalyses[0].split(separator: "\n").prefix(3).joined(separator: "\n") : "")
        
        ### Drawing 2: Safe Place Representation
        \(drawingAnalyses.indices.contains(1) ? drawingAnalyses[1].split(separator: "\n").prefix(3).joined(separator: "\n") : "")
        
        ### Drawing 3: Future Emotional Aspirations
        \(drawingAnalyses.indices.contains(2) ? drawingAnalyses[2].split(separator: "\n").prefix(3).joined(separator: "\n") : "")
        
        ### Integrated Assessment
        The drawing series reveals a progression in emotional expression from your current state through your sense of security to your aspirational emotional future. This pathway provides valuable insights into your emotional processing and resilience mechanisms.
        
        The consistency and evolution across the drawings suggest a dynamic emotional landscape with both areas of stability and growth. The color choices, line quality, and symbolic elements across all three drawings indicate meaningful patterns in how you experience and process emotions.
        
        This assessment should be considered as one component of understanding your emotional wellbeing, ideally complemented by conversation and other forms of emotional expression.
        """
    }
}
