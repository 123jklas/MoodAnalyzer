//
//  ShareController.swift
//  MoodAnalyzer
//
//  Created on 3/1/25.
//

import UIKit
import PDFKit
import SwiftUI

struct ShareController {
    // Create a more reliable sharing mechanism
    static func generateAndSavePDF(
        responses: [(question: Question, score: Int)],
        categoryPercentages: [String: Double],
        drawingImage: UIImage,
        drawingAnalysis: String,
        integratedAssessment: String,
        assessmentNotes: String,
        isGreenMode: Bool
    ) -> URL? {
        // Create a PDF document
        let pageSize = CGSize(width: 8.5 * 72.0, height: 11 * 72.0)
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        
        let data = renderer.pdfData { context in
            // First page - Title and Assessment Summary
            context.beginPage()
            
            // Title
            let titleAttributes = [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)
            ]
            
            let title = "Therapeutic Assessment Report"
            title.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
            
            // Date and Mode
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateString = "Assessment Date: \(dateFormatter.string(from: Date()))"
            dateString.draw(at: CGPoint(x: 50, y: 90), withAttributes: [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)
            ])
            
            let modeString = "Assessment Type: \(isGreenMode ? "Child Assessment (Green Mode)" : "Adult Assessment (Standard Mode)")"
            modeString.draw(at: CGPoint(x: 50, y: 110), withAttributes: [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)
            ])
            
            // Section Headers
            let sectionHeaderAttributes = [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)
            ]
            
            let contentAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)
            ]
            
            var yPos = 150.0
            
            // Assessment Summary
            "Assessment Summary".draw(at: CGPoint(x: 50, y: yPos), withAttributes: sectionHeaderAttributes)
            yPos += 25
            
            // Draw wrapped summary text
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 5
            
            let summaryAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .paragraphStyle: paragraphStyle
            ]
            
            // Calculate average score for overall assessment
            let avgScore = categoryPercentages.values.reduce(0.0, +) / Double(categoryPercentages.count)
            var overallAssessment = ""
            
            if avgScore >= 75.0 {
                overallAssessment = "The assessment indicates a generally positive emotional state. The individual demonstrates strong resilience and coping mechanisms with minimal indicators of psychological distress."
            } else if avgScore >= 60.0 {
                overallAssessment = "The assessment suggests a moderately stable emotional state. While showing adequate coping in several areas, there may be specific aspects that could benefit from supportive intervention."
            } else if avgScore >= 45.0 {
                overallAssessment = "The assessment reveals a mixed emotional state. The individual shows both strengths and potential concerns that warrant closer attention in a therapeutic context."
            } else {
                overallAssessment = "The assessment indicates potential emotional difficulties across multiple domains. A more thorough clinical evaluation is recommended to provide appropriate support and intervention strategies."
            }
            
            let summaryRect = CGRect(x: 50, y: yPos, width: pageSize.width - 100, height: 100)
            let summaryAttributedString = NSAttributedString(string: overallAssessment, attributes: summaryAttributes)
            summaryAttributedString.draw(in: summaryRect)
            
            yPos += 120
            
            // Questionnaire Results
            "Questionnaire Results".draw(at: CGPoint(x: 50, y: yPos), withAttributes: sectionHeaderAttributes)
            yPos += 25
            
            // Process categories into groups
            let strengthCategories = categoryPercentages.filter { $0.value >= 70.0 }.keys.sorted()
            let neutralCategories = categoryPercentages.filter { $0.value >= 40.0 && $0.value < 70.0 }.keys.sorted()
            let concernCategories = categoryPercentages.filter { $0.value < 40.0 }.keys.sorted()
            
            // Draw category bars
            for (category, percentage) in categoryPercentages.sorted(by: { $0.key < $1.key }) {
                // Check if we need a new page
                if yPos > pageSize.height - 50 {
                    context.beginPage()
                    yPos = 50
                }
                
                // Category name
                let categoryText = "\(category): \(Int(percentage))%"
                categoryText.draw(at: CGPoint(x: 50, y: yPos), withAttributes: contentAttributes)
                
                // Bar background and fill
                let barRect = CGRect(x: 50, y: yPos + 15, width: 300, height: 10)
                UIColor.lightGray.setFill()
                UIBezierPath(rect: barRect).fill()
                
                let fillWidth = 300 * (percentage / 100)
                let fillRect = CGRect(x: 50, y: yPos + 15, width: fillWidth, height: 10)
                
                // Color based on percentage
                if percentage >= 70.0 {
                    UIColor.systemGreen.setFill()
                } else if percentage >= 40.0 {
                    UIColor.systemOrange.setFill()
                } else {
                    UIColor.systemRed.setFill()
                }
                UIBezierPath(rect: fillRect).fill()
                
                yPos += 35
            }
            
            // Category groups
            yPos += 10
            if !strengthCategories.isEmpty {
                "Areas of Strength:".draw(at: CGPoint(x: 50, y: yPos), withAttributes: [
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)
                ])
                yPos += 20
                strengthCategories.joined(separator: ", ").draw(at: CGPoint(x: 50, y: yPos), withAttributes: contentAttributes)
                yPos += 25
            }
            
            if !neutralCategories.isEmpty {
                "Areas of Moderate Function:".draw(at: CGPoint(x: 50, y: yPos), withAttributes: [
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)
                ])
                yPos += 20
                neutralCategories.joined(separator: ", ").draw(at: CGPoint(x: 50, y: yPos), withAttributes: contentAttributes)
                yPos += 25
            }
            
            if !concernCategories.isEmpty {
                "Areas of Potential Concern:".draw(at: CGPoint(x: 50, y: yPos), withAttributes: [
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)
                ])
                yPos += 20
                concernCategories.joined(separator: ", ").draw(at: CGPoint(x: 50, y: yPos), withAttributes: contentAttributes)
                yPos += 25
            }
            
            // Start a new page for drawing analysis
            context.beginPage()
            yPos = 50
            
            // Drawing Analysis
            "Drawing Analysis".draw(at: CGPoint(x: 50, y: yPos), withAttributes: sectionHeaderAttributes)
            yPos += 25
            
            // Add the drawing image
            if let cgImage = drawingImage.cgImage {
                // Save the current graphics state
                context.cgContext.saveGState()
                
                // Calculate image rect maintaining aspect ratio
                let imageRect = calculateImageRect(cgImage: cgImage, startX: 50, yPosition: yPos, maxWidth: 300)
                
                // Apply transformations to fix the upside-down issue
                // First translate the origin to the bottom of where we want the image to appear
                context.cgContext.translateBy(x: 0, y: imageRect.origin.y + imageRect.height)
                // Then flip the y-axis
                context.cgContext.scaleBy(x: 1.0, y: -1.0)
                // Draw the image at the transformed origin (0,0)
                context.cgContext.draw(cgImage, in: CGRect(x: imageRect.origin.x, y: 0, width: imageRect.width, height: imageRect.height))
                
                // Restore the graphics state
                context.cgContext.restoreGState()
                
                yPos = imageRect.maxY + 20
            }
            
            // Add the drawing analysis text
            let analysisRect = CGRect(x: 50, y: yPos, width: pageSize.width - 100, height: 150)
            let analysisAttributedString = NSAttributedString(string: drawingAnalysis, attributes: summaryAttributes)
            analysisAttributedString.draw(in: analysisRect)
            
            yPos += 160
            
            // Integrated Assessment
            "Integrated Assessment".draw(at: CGPoint(x: 50, y: yPos), withAttributes: sectionHeaderAttributes)
            yPos += 25
            
            // Check if we might need a new page for the integrated assessment
            if yPos > pageSize.height - 200 {
                context.beginPage()
                yPos = 50
                "Integrated Assessment (continued)".draw(at: CGPoint(x: 50, y: yPos), withAttributes: sectionHeaderAttributes)
                yPos += 25
            }
            
            // Calculate the remaining space on the page
            let remainingHeight = pageSize.height - yPos - 50
            
            // Create a rect for the integrated assessment with appropriate height
            let integratedRect = CGRect(x: 50, y: yPos, width: pageSize.width - 100, height: remainingHeight)
            
            // Create the attributed string
            let integratedAttributedString = NSAttributedString(string: integratedAssessment, attributes: summaryAttributes)
            
            // Get a text container to measure if it will fit
            let textStorage = NSTextStorage(attributedString: integratedAttributedString)
            let textContainer = NSTextContainer(size: CGSize(width: pageSize.width - 100, height: .greatestFiniteMagnitude))
            let layoutManager = NSLayoutManager()
            layoutManager.addTextContainer(textContainer)
            textStorage.addLayoutManager(layoutManager)
            
            // Calculate the height needed for the text
            let textHeight = layoutManager.usedRect(for: textContainer).height
            
            // If it won't fit, create a new page
            if textHeight > remainingHeight {
                // Draw what fits on this page
                integratedAttributedString.draw(in: integratedRect)
                
                // Create a new page for the rest
                context.beginPage()
                yPos = 50
                
                "Integrated Assessment (continued)".draw(at: CGPoint(x: 50, y: yPos), withAttributes: sectionHeaderAttributes)
                yPos += 25
                
                // Draw the rest on the new page
                let continuationRect = CGRect(x: 50, y: yPos, width: pageSize.width - 100, height: pageSize.height - yPos - 50)
                integratedAttributedString.draw(in: continuationRect)
                
                yPos += textHeight + 20
            } else {
                // It fits, so just draw it normally
                integratedAttributedString.draw(in: integratedRect)
                yPos += textHeight + 20
            }
            
            // If there are additional notes, add them
            if !assessmentNotes.isEmpty {
                // Check if we need a new page
                if yPos > pageSize.height - 100 {
                    context.beginPage()
                    yPos = 50
                }
                
                "Additional Notes".draw(at: CGPoint(x: 50, y: yPos), withAttributes: sectionHeaderAttributes)
                yPos += 25
                
                // Calculate remaining space on this page
                let remainingHeight = pageSize.height - yPos - 50
                
                // Create rect for the notes
                let notesRect = CGRect(x: 50, y: yPos, width: pageSize.width - 100, height: remainingHeight)
                let notesAttributedString = NSAttributedString(string: assessmentNotes, attributes: summaryAttributes)
                
                // Similar approach as integrated assessment to check if we need a new page
                let textStorage = NSTextStorage(attributedString: notesAttributedString)
                let textContainer = NSTextContainer(size: CGSize(width: pageSize.width - 100, height: .greatestFiniteMagnitude))
                let layoutManager = NSLayoutManager()
                layoutManager.addTextContainer(textContainer)
                textStorage.addLayoutManager(layoutManager)
                
                let textHeight = layoutManager.usedRect(for: textContainer).height
                
                if textHeight > remainingHeight {
                    // Draw what fits
                    notesAttributedString.draw(in: notesRect)
                    
                    // Start a new page for the rest
                    context.beginPage()
                    yPos = 50
                    
                    "Additional Notes (continued)".draw(at: CGPoint(x: 50, y: yPos), withAttributes: sectionHeaderAttributes)
                    yPos += 25
                    
                    let continuationRect = CGRect(x: 50, y: yPos, width: pageSize.width - 100, height: pageSize.height - yPos - 50)
                    notesAttributedString.draw(in: continuationRect)
                } else {
                    // It fits, so just draw it
                    notesAttributedString.draw(in: notesRect)
                }
            }
        }
        
        // Save to temporary file
        let tmpDirURL = FileManager.default.temporaryDirectory
        let fileName = "MoodAnalyzerReport-\(Date().timeIntervalSince1970).pdf"
        let fileURL = tmpDirURL.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error writing PDF to temporary file: \(error)")
            return nil
        }
    }
    
    // Helper function to calculate image rect maintaining aspect ratio
    private static func calculateImageRect(cgImage: CGImage, startX: CGFloat, yPosition: CGFloat, maxWidth: CGFloat) -> CGRect {
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        
        let aspectRatio = imageWidth / imageHeight
        
        let width = min(maxWidth, imageWidth)
        let height = width / aspectRatio
        
        return CGRect(x: startX, y: yPosition, width: width, height: height)
    }
}

// Simple ShareSheet that works more reliably
struct SimpleShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to update
    }
}
