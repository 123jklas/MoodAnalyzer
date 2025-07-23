//
//  PDFGenerator.swift
//  MoodAnalyzer
//
//  Created on 3/1/25.
//

import UIKit
import PDFKit

class PDFGenerator {
    // Generate PDF from report data
    static func generatePDF(
        responses: [(question: Question, score: Int)],
        categoryPercentages: [String: Double],
        drawingImage: UIImage,
        drawingAnalysis: String,
        integratedAssessment: String,
        assessmentNotes: String,
        isGreenMode: Bool
    ) -> PDFDocument {
        // Create a PDF document
        let pdfMetaData = [
            kCGPDFContextCreator: "MoodAnalyzer",
            kCGPDFContextAuthor: "MoodAnalyzer App",
            kCGPDFContextTitle: "Therapeutic Assessment Report"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            // First page
            context.beginPage()
            
            // Title
            let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont
            ]
            
            let title = "Therapeutic Assessment Report"
            let titleSize = title.size(withAttributes: titleAttributes)
            let titlePoint = CGPoint(x: (pageWidth - titleSize.width) / 2, y: 50)
            title.draw(at: titlePoint, withAttributes: titleAttributes)
            
            // Date
            let dateFont = UIFont.systemFont(ofSize: 12)
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: dateFont
            ]
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateString = "Date: \(dateFormatter.string(from: Date()))"
            dateString.draw(at: CGPoint(x: 72, y: 90), withAttributes: dateAttributes)
            
            // Assessment type
            let typeString = "Assessment Type: \(isGreenMode ? "Child Assessment (Green Mode)" : "Adult Assessment (Standard Mode)")"
            typeString.draw(at: CGPoint(x: 72, y: 110), withAttributes: dateAttributes)
            
            // Summary section
            let sectionFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
            let sectionAttributes: [NSAttributedString.Key: Any] = [
                .font: sectionFont
            ]
            
            let summaryTitle = "Assessment Summary"
            summaryTitle.draw(at: CGPoint(x: 72, y: 150), withAttributes: sectionAttributes)
            
            let contentFont = UIFont.systemFont(ofSize: 12)
            let contentAttributes: [NSAttributedString.Key: Any] = [
                .font: contentFont
            ]
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 6
            let wrappedAttributes: [NSAttributedString.Key: Any] = [
                .font: contentFont,
                .paragraphStyle: paragraphStyle
            ]
            
            // Draw wrapped text - implementation would wrap text properly
            drawText(integratedAssessment, rect: CGRect(x: 72, y: 180, width: pageWidth - 144, height: 150), attributes: wrappedAttributes)
            
            // Questionnaire Results
            let resultsTitle = "Questionnaire Results"
            resultsTitle.draw(at: CGPoint(x: 72, y: 350), withAttributes: sectionAttributes)
            
            // Draw category bars
            var yPosition = 380.0
            for (category, percentage) in categoryPercentages.sorted(by: { $0.key < $1.key }) {
                // Category name
                let categoryText = "\(category): \(Int(percentage))%"
                categoryText.draw(at: CGPoint(x: 72, y: yPosition), withAttributes: contentAttributes)
                
                // Bar background
                let barRect = CGRect(x: 72, y: yPosition + 20, width: 300, height: 15)
                UIColor.lightGray.setFill()
                UIBezierPath(rect: barRect).fill()
                
                // Bar fill based on percentage
                let fillWidth = 300 * (percentage / 100)
                let fillRect = CGRect(x: 72, y: yPosition + 20, width: fillWidth, height: 15)
                barColor(for: percentage).setFill()
                UIBezierPath(rect: fillRect).fill()
                
                yPosition += 50
            }
            
            // Check if we need a new page for drawing
            if yPosition > pageHeight - 300 {
                context.beginPage()
                yPosition = 50
            }
            
            // Drawing Analysis
            let drawingTitle = "Drawing Analysis"
            drawingTitle.draw(at: CGPoint(x: 72, y: yPosition), withAttributes: sectionAttributes)
            
            // Draw the image (scaled appropriately)
            if let cgImage = drawingImage.cgImage {
                yPosition += 30
                let imageRect = calculateImageRect(cgImage: cgImage, yPosition: yPosition, maxWidth: pageWidth - 144)
                context.cgContext.draw(cgImage, in: imageRect)
                yPosition = imageRect.maxY + 20
            }
            
            // Drawing analysis text
            drawText(drawingAnalysis, rect: CGRect(x: 72, y: yPosition, width: pageWidth - 144, height: 200), attributes: wrappedAttributes)
            
            // Add any additional notes if present
            if !assessmentNotes.isEmpty {
                yPosition += 220
                
                // Check if we need a new page
                if yPosition > pageHeight - 100 {
                    context.beginPage()
                    yPosition = 50
                }
                
                let notesTitle = "Additional Notes"
                notesTitle.draw(at: CGPoint(x: 72, y: yPosition), withAttributes: sectionAttributes)
                
                yPosition += 30
                drawText(assessmentNotes, rect: CGRect(x: 72, y: yPosition, width: pageWidth - 144, height: 150), attributes: wrappedAttributes)
            }
            
            // Footer
            let footerText = "Generated by MoodAnalyzer App - For clinical use only"
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 10)
            ]
            let footerSize = footerText.size(withAttributes: footerAttributes)
            footerText.draw(at: CGPoint(x: (pageWidth - footerSize.width) / 2, y: pageHeight - 50), withAttributes: footerAttributes)
        }
        
        return PDFDocument(data: data)!
    }
    
    // Helper function to draw wrapped text
    private static func drawText(_ text: String, rect: CGRect, attributes: [NSAttributedString.Key: Any]) {
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        attributedString.draw(in: rect)
    }
    
    // Helper function to calculate image rect maintaining aspect ratio
    private static func calculateImageRect(cgImage: CGImage, yPosition: CGFloat, maxWidth: CGFloat) -> CGRect {
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        
        let aspectRatio = imageWidth / imageHeight
        
        let width = min(maxWidth, imageWidth)
        let height = width / aspectRatio
        
        return CGRect(x: 72, y: yPosition, width: width, height: height)
    }
    
    // Helper function to get color for percentage
    private static func barColor(for percentage: Double) -> UIColor {
        if percentage >= 70.0 {
            return UIColor.systemGreen
        } else if percentage >= 40.0 {
            return UIColor.systemOrange
        } else {
            return UIColor.systemRed
        }
    }
}
