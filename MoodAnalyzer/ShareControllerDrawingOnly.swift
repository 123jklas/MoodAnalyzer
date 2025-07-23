import UIKit
import PDFKit
import SwiftUI

// Extension to ShareController to add support for drawing-only mode
extension ShareController {
    // Generate PDF specifically for drawing-only mode with multiple drawings
    static func generateAndSaveDrawingOnlyPDF(
        drawingImages: [UIImage],
        drawingAnalyses: [String],
        drawingPrompts: [String],
        cumulativeAnalysis: String,
        assessmentNotes: String
    ) -> URL? {
        // Create a PDF document
        let pageSize = CGSize(width: 8.5 * 72.0, height: 11 * 72.0)
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        
        let data = renderer.pdfData { context in
            // Title page
            context.beginPage()
            
            // Title
            let titleAttributes = [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)
            ]
            
            let title = "Drawing Series Assessment Report"
            title.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
            
            // Date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateString = "Assessment Date: \(dateFormatter.string(from: Date()))"
            dateString.draw(at: CGPoint(x: 50, y: 90), withAttributes: [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)
            ])
            
            let modeString = "Assessment Type: Drawing Series Assessment"
            modeString.draw(at: CGPoint(x: 50, y: 110), withAttributes: [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)
            ])
            
            // Description
            let descriptionText = """
            This assessment uses a series of guided drawing exercises to explore emotional expression. 
            The process involves three drawing prompts, each designed to elicit different aspects of 
            emotional experience and provide a holistic view of emotional patterns.
            """
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 5
            
            let descriptionAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .paragraphStyle: paragraphStyle
            ]
            
            let descriptionRect = CGRect(x: 50, y: 150, width: pageSize.width - 100, height: 100)
            let descriptionAttributedString = NSAttributedString(string: descriptionText, attributes: descriptionAttributes)
            descriptionAttributedString.draw(in: descriptionRect)
            
            // For each drawing, add a section
            var yPos = 250.0
            
            for i in 0..<min(drawingImages.count, min(drawingAnalyses.count, drawingPrompts.count)) {
                // Check if we need to start a new page
                if yPos > pageSize.height - 250 {
                    context.beginPage()
                    yPos = 50
                }
                
                // Section header
                let drawingHeader = "Drawing \(i + 1)"
                drawingHeader.draw(at: CGPoint(x: 50, y: yPos), withAttributes: [
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)
                ])
                yPos += 25
                
                // Prompt
                let promptHeader = "Prompt:"
                promptHeader.draw(at: CGPoint(x: 50, y: yPos), withAttributes: [
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12)
                ])
                yPos += 20
                
                // Draw the prompt text
                let promptRect = CGRect(x: 50, y: yPos, width: pageSize.width - 100, height: 50)
                let promptAttributedString = NSAttributedString(string: drawingPrompts[i], attributes: [
                    .font: UIFont.italicSystemFont(ofSize: 12),
                    .paragraphStyle: paragraphStyle
                ])
                promptAttributedString.draw(in: promptRect)
                yPos += 60
                
                // Check if we need to start a new page for the image
                if yPos > pageSize.height - 200 {
                    context.beginPage()
                    yPos = 50
                }
                
                // Add the drawing image
                if let cgImage = drawingImages[i].cgImage {
                    // Save the current graphics state
                    context.cgContext.saveGState()
                    
                    // Calculate image rect maintaining aspect ratio
                    let imageRect = calculateImageRectForDrawing(cgImage: cgImage, startX: 50, yPosition: yPos, maxWidth: 300)
                    
                    // Apply transformations to fix the upside-down issue
                    context.cgContext.translateBy(x: 0, y: imageRect.origin.y + imageRect.height)
                    context.cgContext.scaleBy(x: 1.0, y: -1.0)
                    context.cgContext.draw(cgImage, in: CGRect(x: imageRect.origin.x, y: 0, width: imageRect.width, height: imageRect.height))
                    
                    // Restore the graphics state
                    context.cgContext.restoreGState()
                    
                    yPos = imageRect.maxY + 20
                }
                
                // Check if we need a new page for the analysis
                if yPos > pageSize.height - 150 {
                    context.beginPage()
                    yPos = 50
                }
                
                // Analysis header
                let analysisHeader = "Analysis:"
                analysisHeader.draw(at: CGPoint(x: 50, y: yPos), withAttributes: [
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12)
                ])
                yPos += 20
                
                // Get a shortened version of the analysis for this drawing
                let analysisText = getShortenedAnalysis(from: drawingAnalyses[i])
                
                // Draw the analysis text
                let analysisRect = CGRect(x: 50, y: yPos, width: pageSize.width - 100, height: 150)
                let analysisAttributedString = NSAttributedString(string: analysisText, attributes: descriptionAttributes)
                analysisAttributedString.draw(in: analysisRect)
                
                yPos += 180
                
                // Add a separator
                context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
                context.cgContext.setLineWidth(0.5)
                context.cgContext.move(to: CGPoint(x: 50, y: yPos))
                context.cgContext.addLine(to: CGPoint(x: pageSize.width - 50, y: yPos))
                context.cgContext.strokePath()
                
                yPos += 30
            }
            
            // Start a new page for cumulative analysis
            context.beginPage()
            
            // Cumulative Analysis heading
            let cumulativeHeader = "Comprehensive Assessment"
            cumulativeHeader.draw(at: CGPoint(x: 50, y: 50), withAttributes: [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)
            ])
            
            // Draw the cumulative analysis
            let cumulativeRect = CGRect(x: 50, y: 80, width: pageSize.width - 100, height: pageSize.height - 130)
            let cumulativeAttributedString = NSAttributedString(string: cumulativeAnalysis, attributes: descriptionAttributes)
            cumulativeAttributedString.draw(in: cumulativeRect)
            
            // Add notes if present
            if !assessmentNotes.isEmpty {
                context.beginPage()
                
                let notesHeader = "Additional Notes"
                notesHeader.draw(at: CGPoint(x: 50, y: 50), withAttributes: [
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)
                ])
                
                let notesRect = CGRect(x: 50, y: 80, width: pageSize.width - 100, height: pageSize.height - 130)
                let notesAttributedString = NSAttributedString(string: assessmentNotes, attributes: descriptionAttributes)
                notesAttributedString.draw(in: notesRect)
            }
            
            // Footer on all pages
            let footerText = "Generated by MoodAnalyzer - Drawing Series Assessment"
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 10)
            ]
            let footerSize = footerText.size(withAttributes: footerAttributes)
            footerText.draw(at: CGPoint(x: (pageSize.width - footerSize.width) / 2, y: pageSize.height - 30), withAttributes: footerAttributes)
        }
        
        // Save to temporary file
        let tmpDirURL = FileManager.default.temporaryDirectory
        let fileName = "DrawingSeriesReport-\(Date().timeIntervalSince1970).pdf"
        let fileURL = tmpDirURL.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error writing PDF to temporary file: \(error)")
            return nil
        }
    }
    
    // Helper function to calculate image rect maintaining aspect ratio - accessible version
    static func calculateImageRectForDrawing(cgImage: CGImage, startX: CGFloat, yPosition: CGFloat, maxWidth: CGFloat) -> CGRect {
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        
        let aspectRatio = imageWidth / imageHeight
        
        let width = min(maxWidth, imageWidth)
        let height = width / aspectRatio
        
        return CGRect(x: startX, y: yPosition, width: width, height: height)
    }
    
    // Helper function to get a shortened version of analysis for PDF
    static func getShortenedAnalysis(from fullAnalysis: String) -> String {
        // Get first few paragraphs
        let paragraphs = fullAnalysis.components(separatedBy: "\n\n")
        if paragraphs.count > 2 {
            return paragraphs[0...1].joined(separator: "\n\n") + "\n\n..."
        }
        return fullAnalysis
    }
}
