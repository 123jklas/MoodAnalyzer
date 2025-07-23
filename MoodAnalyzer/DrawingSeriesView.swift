import SwiftUI

struct DrawingSeriesView: View {
    let drawings: [UIImage]
    let analyses: [String]
    let prompts: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Drawing Series Analysis")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 5)
            
            ForEach(0..<min(drawings.count, min(analyses.count, prompts.count)), id: \.self) { index in
                VStack(alignment: .leading, spacing: 10) {
                    // Drawing number with indicator
                    HStack {
                        Text("Drawing \(index + 1)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(colorForIndex(index))
                            )
                        
                        Spacer()
                    }
                    
                    // Prompt given - with correct number
                    if index < prompts.count {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Prompt: #\(index + 1) of \(prompts.count)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .italic()
                            
                            Text(prompts[index])
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(UIColor.systemGray6))
                        )
                    }
                    
                    // Drawing image
                    Image(uiImage: drawings[index])
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .cornerRadius(8)
                        .padding(.vertical, 5)
                    
                    // Analysis summary (first paragraph only)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Analysis Highlights:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(getSummary(from: analyses[index]))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(UIColor.systemGray6))
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(colorForIndex(index).opacity(0.5), lineWidth: 1)
                        .background(Color(UIColor.systemBackground))
                )
                .padding(.bottom, 10)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
    
    // Returns a different color for each drawing index
    private func colorForIndex(_ index: Int) -> Color {
        let colors: [Color] = [.blue, .green, .purple]
        return colors[index % colors.count]
    }
    
    // Gets a summary from the analysis text (first paragraph or first few sentences)
    private func getSummary(from analysis: String) -> String {
        // Look for the first paragraph
        if let paragraph = analysis.components(separatedBy: "\n\n").first,
           !paragraph.isEmpty {
            // Truncate if too long
            if paragraph.count > 300 {
                let truncated = String(paragraph.prefix(300))
                return truncated + "..."
            }
            return paragraph
        }
        
        // Fallback to first few sentences if no paragraph break
        let sentences = analysis.components(separatedBy: ". ")
        if sentences.count > 3 {
            return sentences.prefix(3).joined(separator: ". ") + "..."
        }
        
        // Return the whole text if it's short
        if analysis.count > 300 {
            return String(analysis.prefix(300)) + "..."
        }
        return analysis
    }
}
