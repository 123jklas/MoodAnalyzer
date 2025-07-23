import SwiftUI
import PDFKit

struct FinalReportView: View {
    let responses: [(question: Question, score: Int)]
    let drawingAnalysis: String
    let drawingImage: UIImage
    let isGreenMode: Bool
    
    // Additional properties for drawing-only mode
    var allDrawings: [UIImage]?
    var allAnalyses: [String]?
    var drawingPrompts: [String]?
    var isDrawingOnlyMode: Bool {
        return responses.isEmpty && allDrawings != nil && allAnalyses != nil
    }
    
    @State private var assessmentNotes: String = ""
    @State private var showingPDFPreview = false
    @State private var showingShareSheet = false
    @State private var pdfDocument: PDFDocument?
    @State private var sharingItems: [Any] = []
    
    // Computed property to process category percentages
    var categoryPercentages: [String: Double] {
        var dict: [String: (sum: Int, count: Int)] = [:]
        for response in responses {
            let cat = response.question.category
            dict[cat, default: (0,0)].sum += response.score
            dict[cat, default: (0,0)].count += 1
        }
        var percentages: [String: Double] = [:]
        for (cat, data) in dict {
            let maxScore = data.count * 5
            percentages[cat] = (Double(data.sum) / Double(maxScore)) * 100.0
        }
        return percentages
    }
    
    // For drawing-only mode, estimate emotional metrics
    var estimatedEmotionalMetrics: EmotionalMetrics {
        if isDrawingOnlyMode {
            // Create estimated metrics based on drawing analysis only
            return EmotionalMetrics(
                expressionLevel: 0.7, // Example values - in real implementation,
                emotionalBalance: 0.6, // these would be calculated from the drawing analyses
                creativeEnergy: 0.8,
                joy: 0.65,
                calm: 0.55,
                energy: 0.7,
                tension: 0.4,
                expression: 0.75
            )
        } else {
            // Use the standard calculation for normal modes
            return EmotionalMetrics.calculateFromAssessment(
                responses: responses,
                drawingAnalysis: drawingAnalysis,
                categoryPercentages: categoryPercentages
            )
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Assessment Information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Assessment Information")
                            .font(.headline)
                            .padding(.bottom, 2)
                        
                        Text("Assessment Date: \(formattedDate())")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("Assessment Type: \(getAssessmentTypeText())")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Analysis Metrics View
                    AnalysisMetricsView(metrics: estimatedEmotionalMetrics)
                        .padding(.horizontal)
                    
                    // Emotional Expression Profile Chart
                    EmotionalProfileChart(metrics: estimatedEmotionalMetrics)
                        .padding(.horizontal)
                        .frame(height: 500)
                    
                    Divider()
                    
                    // Drawing Series View for drawing-only mode
                    if isDrawingOnlyMode, let drawings = allDrawings, let analyses = allAnalyses, let prompts = drawingPrompts {
                        DrawingSeriesView(drawings: drawings, analyses: analyses, prompts: prompts)
                            .padding(.horizontal)
                    } else {
                        // Standard views for regular and green modes
                        
                        // Assessment Summary
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Assessment Summary")
                                .font(.headline)
                                .padding(.bottom, 2)
                            
                            Text(isDrawingOnlyMode ? drawingAnalysis : overallAssessment)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(UIColor.systemGray6))
                                )
                        }
                        .padding(.horizontal)
                        
                        // Only show questionnaire results for non-drawing-only modes
                        if !isDrawingOnlyMode {
                            Divider()
                            
                            // Questionnaire Results
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Questionnaire Results")
                                    .font(.headline)
                                    .padding(.bottom, 2)
                                
                                ForEach(categoryPercentages.keys.sorted(), id: \.self) { category in
                                    if let percentage = categoryPercentages[category] {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("\(category): \(Int(percentage))%")
                                                .font(.subheadline)
                                            GeometryReader { geometry in
                                                Rectangle()
                                                    .fill(categoryColor(percentage))
                                                    .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 16)
                                                    .cornerRadius(3)
                                            }
                                            .frame(height: 16)
                                        }
                                        .padding(.vertical, 3)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    if !strengthCategories.isEmpty {
                                        Text("Areas of Strength:")
                                            .fontWeight(.semibold)
                                        Text(strengthCategories.joined(separator: ", "))
                                    }
                                    
                                    if !neutralCategories.isEmpty {
                                        Text("Areas of Moderate Function:")
                                            .fontWeight(.semibold)
                                            .padding(.top, 5)
                                        Text(neutralCategories.joined(separator: ", "))
                                    }
                                    
                                    if !concernCategories.isEmpty {
                                        Text("Areas of Potential Concern:")
                                            .fontWeight(.semibold)
                                            .padding(.top, 5)
                                        Text(concernCategories.joined(separator: ", "))
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(UIColor.systemGray6))
                                )
                            }
                            .padding(.horizontal)
                        }
                        
                        Divider()
                        
                        // Drawing Analysis
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Drawing Analysis")
                                .font(.headline)
                                .padding(.bottom, 2)
                            
                            Image(uiImage: drawingImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .cornerRadius(10)
                                .padding(.vertical, 10)
                            
                            Text(drawingAnalysis)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(UIColor.systemGray6))
                                )
                        }
                        .padding(.horizontal)
                        
                        Divider()
                        
                        // Integrated Assessment
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Integrated Assessment")
                                .font(.headline)
                                .padding(.bottom, 2)
                            
                            Text(isDrawingOnlyMode ? drawingAnalysis : integratedAssessment())
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(UIColor.systemGray6))
                                )
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                    
                    // Additional Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional Notes")
                            .font(.headline)
                            .padding(.bottom, 2)
                        
                        TextEditor(text: $assessmentNotes)
                            .frame(height: 150)
                            .padding(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    
                    // Actions section
                    HStack(spacing: 15) {
                        Button(action: {
                            generateAndViewPDF()
                        }) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Generate PDF")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            generateAndSharePDF()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Report")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }
                .padding(.vertical)
            }
            .navigationTitle("Assessment Report")
            .sheet(isPresented: $showingPDFPreview) {
                if let pdfDocument = pdfDocument {
                    PDFPreviewView(document: pdfDocument)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                SimpleShareSheet(items: sharingItems)
            }
        }
    }
    
    // Process categories into groups (for questionnaire-based modes)
    var strengthCategories: [String] {
        return categoryPercentages.filter { $0.value >= 70.0 }.keys.sorted()
    }
    
    var neutralCategories: [String] {
        return categoryPercentages.filter { $0.value >= 40.0 && $0.value < 70.0 }.keys.sorted()
    }
    
    var concernCategories: [String] {
        return categoryPercentages.filter { $0.value < 40.0 }.keys.sorted()
    }
    
    private func getAssessmentTypeText() -> String {
        if isDrawingOnlyMode {
            return "Drawing Series Assessment"
        } else if isGreenMode {
            return "Child Assessment (Green Mode)"
        } else {
            return "Adult Assessment (Standard Mode)"
        }
    }
    
    private func categoryColor(_ percentage: Double) -> Color {
        if percentage >= 70.0 {
            return Color.green
        } else if percentage >= 40.0 {
            return Color.orange
        } else {
            return Color.red
        }
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }
    
    private func integratedAssessment() -> String {
        // Existing code for regular and green modes
        // Integrating questionnaire and drawing analysis
        let avgScore = categoryPercentages.values.reduce(0.0, +) / Double(categoryPercentages.count)
        
        // Extract emotional tone from drawing analysis
        let drawingEmotionalTone = determineEmotionalTone(from: drawingAnalysis)
        
        // Create integrated assessment based on consistency between questionnaire and drawing
        let consistencyAssessment = assessConsistency(questionnaireScore: avgScore, drawingTone: drawingEmotionalTone)
        
        let assessmentMode = isGreenMode ? "child-appropriate" : "adult"
        
        return """
        This integrated assessment combines structured questionnaire responses with expressive drawing analysis to provide a more complete picture of the individual's emotional state.
        
        The questionnaire results (overall score: \(Int(avgScore))%) and the drawing analysis (emotional tone: \(drawingEmotionalTone)) \(consistencyAssessment)
        
        Based on the emotional metrics, this individual shows \(estimatedEmotionalMetrics.expressionLevelText.lowercased()) expression levels with \(estimatedEmotionalMetrics.emotionalBalanceText.lowercased()) emotional balance and \(estimatedEmotionalMetrics.creativeEnergyText.lowercased()) creative energy. The emotional profile indicates particular strength in \(identifyStrongestDimension()).
        
        This assessment was conducted using the \(assessmentMode) assessment framework and should be interpreted within the appropriate developmental context.
        
        Note: This report is designed as a clinical aid and should be used in conjunction with professional clinical judgment and additional assessment methods as appropriate.
        """
    }
    
    private func identifyStrongestDimension() -> String {
        let dimensions = [
            ("calm", estimatedEmotionalMetrics.calm),
            ("joy", estimatedEmotionalMetrics.joy),
            ("emotional expression", estimatedEmotionalMetrics.expression),
            ("energy", estimatedEmotionalMetrics.energy)
        ]
        
        // Find the dimension with the highest value
        if let strongest = dimensions.max(by: { $0.1 < $1.1 }) {
            return strongest.0
        }
        
        return "balanced emotional dimensions"
    }
    
    private func determineEmotionalTone(from analysis: String) -> String {
        // This is a simplified approach - in a real app, you might use more sophisticated NLP
        let lowerAnalysis = analysis.lowercased()
        
        if lowerAnalysis.contains("happy") || lowerAnalysis.contains("joy") || lowerAnalysis.contains("positive") ||
           lowerAnalysis.contains("confident") || lowerAnalysis.contains("optimistic") {
            return "positive"
        } else if lowerAnalysis.contains("sad") || lowerAnalysis.contains("depress") || lowerAnalysis.contains("negative") ||
                  lowerAnalysis.contains("anxious") || lowerAnalysis.contains("stress") || lowerAnalysis.contains("worry") {
            return "negative"
        } else if lowerAnalysis.contains("mixed") || lowerAnalysis.contains("ambivalent") || lowerAnalysis.contains("complex") {
            return "mixed"
        } else {
            return "neutral"
        }
    }
    
    private func assessConsistency(questionnaireScore: Double, drawingTone: String) -> String {
        let questionnairePositive = questionnaireScore >= 65.0
        let questionnaireNegative = questionnaireScore < 40.0
        let questionnaireMixed = !questionnairePositive && !questionnaireNegative
        
        let drawingPositive = drawingTone == "positive"
        let drawingNegative = drawingTone == "negative"
        let drawingMixed = drawingTone == "mixed" || drawingTone == "neutral"
        
        if (questionnairePositive && drawingPositive) || (questionnaireNegative && drawingNegative) || (questionnaireMixed && drawingMixed) {
            return "show strong consistency, suggesting the assessment likely reflects the individual's authentic emotional state."
        } else if (questionnairePositive && drawingNegative) || (questionnaireNegative && drawingPositive) {
            return "show significant discrepancy, which may indicate complex emotional processing, potential response bias in the questionnaire, or unexpressed feelings that emerged in the drawing task."
        } else {
            return "show partial alignment with some inconsistencies, which is common when comparing structured and expressive assessment methods."
        }
    }
    
    // Overall emotional state assessment
    var overallAssessment: String {
        if isDrawingOnlyMode {
            return drawingAnalysis
        }
        
        let averageScore = categoryPercentages.values.reduce(0.0, +) / Double(categoryPercentages.count)
        
        if averageScore >= 75.0 {
            return "The assessment indicates a generally positive emotional state. The individual demonstrates strong resilience and coping mechanisms with minimal indicators of psychological distress."
        } else if averageScore >= 60.0 {
            return "The assessment suggests a moderately stable emotional state. While showing adequate coping in several areas, there may be specific aspects that could benefit from supportive intervention."
        } else if averageScore >= 45.0 {
            return "The assessment reveals a mixed emotional state. The individual shows both strengths and potential concerns that warrant closer attention in a therapeutic context."
        } else {
            return "The assessment indicates potential emotional difficulties across multiple domains. A more thorough clinical evaluation is recommended to provide appropriate support and intervention strategies."
        }
    }
    
    // PDF generation and sharing functions
    private func generateAndViewPDF() {
        if let fileURL = generatePDFFile() {
            let pdfDoc = PDFDocument(url: fileURL)
            self.pdfDocument = pdfDoc
            showingPDFPreview = true
        }
    }
    
    private func generateAndSharePDF() {
        if let fileURL = generatePDFFile() {
            sharingItems = [fileURL]
            showingShareSheet = true
        }
    }
    
    private func generatePDFFile() -> URL? {
        // Use different PDF generation methods depending on the mode
        if isDrawingOnlyMode, let drawings = allDrawings, let analyses = allAnalyses, let prompts = drawingPrompts {
            return ShareController.generateAndSaveDrawingOnlyPDF(
                drawingImages: drawings,
                drawingAnalyses: analyses,
                drawingPrompts: prompts,
                cumulativeAnalysis: drawingAnalysis,
                assessmentNotes: assessmentNotes
            )
        } else {
            // Use the standard method for regular and green modes
            return ShareController.generateAndSavePDF(
                responses: responses,
                categoryPercentages: categoryPercentages,
                drawingImage: drawingImage,
                drawingAnalysis: drawingAnalysis,
                integratedAssessment: isDrawingOnlyMode ? drawingAnalysis : integratedAssessment(),
                assessmentNotes: assessmentNotes,
                isGreenMode: isGreenMode
            )
        }
    }
}

// PDF Preview View
struct PDFPreviewView: UIViewRepresentable {
    let document: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = document
    }
}
