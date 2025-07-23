//
//  EmotionalMetricsView.swift
//  MoodAnalyzer
//
//  Fixed layout version with improved label visibility
//

import SwiftUI

struct EmotionalMetrics {
    var expressionLevel: Double // 0-1
    var emotionalBalance: Double // 0-1
    var creativeEnergy: Double // 0-1
    var joy: Double // 0-1
    var calm: Double // 0-1
    var energy: Double // 0-1
    var tension: Double // 0-1
    var expression: Double // 0-1
    
    // Classification functions
    var expressionLevelText: String {
        if expressionLevel >= 0.7 { return "High" }
        else if expressionLevel >= 0.4 { return "Moderate" }
        else { return "Low" }
    }
    
    var emotionalBalanceText: String {
        if emotionalBalance >= 0.7 { return "High" }
        else if emotionalBalance >= 0.4 { return "Moderate" }
        else { return "Low" }
    }
    
    var creativeEnergyText: String {
        if creativeEnergy >= 0.7 { return "High" }
        else if creativeEnergy >= 0.4 { return "Moderate" }
        else { return "Low" }
    }
    
    var expressionDirection: String {
        if expressionLevel > 0.5 { return "Positive" }
        else { return "Reserved" }
    }
    
    var balanceDirection: String {
        if emotionalBalance > 0.5 { return "Stable" }
        else { return "Variable" }
    }
    
    var energyDirection: String {
        if creativeEnergy > 0.6 { return "Dynamic" }
        else { return "Steady" }
    }
    
    var isExpressionPositive: Bool {
        return expressionLevel > 0.5
    }
    
    var isBalancePositive: Bool {
        return emotionalBalance > 0.5
    }
    
    var isEnergyPositive: Bool {
        return creativeEnergy > 0.6
    }
}

struct AnalysisMetricsView: View {
    let metrics: EmotionalMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Analysis Metrics")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.bottom, 5)
            
            // Three columns for metrics using Grid layout
            Grid(alignment: .leading, horizontalSpacing: 15, verticalSpacing: 10) {
                GridRow {
                    Text("Expression\nLevel")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Text("Emotional\nBalance")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Text("Creative\nEnergy")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                GridRow {
                    Text(metrics.expressionLevelText)
                        .font(.system(size: 28, weight: .bold))
                    
                    Text(metrics.emotionalBalanceText)
                        .font(.system(size: 28, weight: .bold))
                    
                    Text(metrics.creativeEnergyText)
                        .font(.system(size: 28, weight: .bold))
                }
                
                GridRow {
                    HStack(spacing: 4) {
                        Image(systemName: metrics.isExpressionPositive ? "arrow.up" : "arrow.down")
                            .foregroundColor(metrics.isExpressionPositive ? .green : .orange)
                        
                        Text(metrics.expressionDirection)
                            .font(.subheadline)
                            .foregroundColor(metrics.isExpressionPositive ? .green : .orange)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: metrics.isBalancePositive ? "arrow.up" : "arrow.down")
                            .foregroundColor(metrics.isBalancePositive ? .green : .orange)
                        
                        Text(metrics.balanceDirection)
                            .font(.subheadline)
                            .foregroundColor(metrics.isBalancePositive ? .green : .orange)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: metrics.isEnergyPositive ? "arrow.up" : "arrow.down")
                            .foregroundColor(metrics.isEnergyPositive ? .green : .yellow)
                        
                        Text(metrics.energyDirection)
                            .font(.subheadline)
                            .foregroundColor(metrics.isEnergyPositive ? .green : .yellow)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
    }
}

struct EmotionalProfileChart: View {
    let metrics: EmotionalMetrics
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Emotional Expression Profile")
                .font(.headline)
                .padding(.vertical, 5)
            
            RadarChartView(
                data: [
                    metrics.calm,
                    metrics.joy,
                    metrics.expression,
                    metrics.tension,
                    metrics.energy
                ],
                labels: ["Calm", "Joy", "Expression", "Tension", "Energy"]
            )
            .aspectRatio(1, contentMode: .fit)
            .padding()
        }
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
    }
}

// Refined Radar Chart with better positioning and improved label visibility
struct RadarChartView: View {
    let data: [Double] // Values between 0 and 1
    let labels: [String]
    
    private let gridColor = Color.gray.opacity(0.3)
    private let dataColor = Color.blue.opacity(0.7)
    private let outlineColor = Color.blue
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background circles - grid
                ForEach(0..<4) { i in
                    let scale = Double(i + 1) / 5.0
                    Circle()
                        .stroke(gridColor, lineWidth: 1)
                        .frame(width: geometry.size.width * CGFloat(scale),
                               height: geometry.size.width * CGFloat(scale))
                }
                
                // Scale labels
                ForEach(1..<5) { i in
                    let value = Double(i) * 0.2
                    Text(String(format: "%.1f", value))
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                        .position(x: geometry.size.width/2,
                                 y: geometry.size.height/2 - CGFloat(value) * geometry.size.height/2 + 5)
                }
                
                // Axis lines
                ForEach(0..<data.count, id: \.self) { i in
                    Path { path in
                        path.move(to: CGPoint(x: geometry.size.width/2, y: geometry.size.height/2))
                        path.addLine(to: pointOnCircle(
                            center: CGPoint(x: geometry.size.width/2, y: geometry.size.height/2),
                            radius: geometry.size.width/2,
                            angle: angleFor(index: i, total: data.count)
                        ))
                    }
                    .stroke(gridColor, lineWidth: 1)
                }
                
                // Data polygon
                dataPolygon(in: geometry.size)
                    .fill(dataColor)
                
                // Data polygon outline
                dataPolygon(in: geometry.size)
                    .stroke(outlineColor, lineWidth: 2)
                
                // Labels with improved visibility for both light and dark mode
                ForEach(0..<data.count, id: \.self) { i in
                    let angle = angleFor(index: i, total: data.count)
                    let radius = geometry.size.width/2 + 20
                    let point = pointOnCircle(
                        center: CGPoint(x: geometry.size.width/2, y: geometry.size.height/2),
                        radius: radius,
                        angle: angle
                    )
                    
                    // Create a label with background for better visibility
                    Text(labels[i])
                        .font(.caption)
                        .foregroundColor(.primary) // Uses system text color for better visibility in any mode
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(UIColor.systemBackground).opacity(0.7)) // Semi-transparent background
                                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                        )
                        .position(adjustLabelPosition(for: point, label: labels[i], angle: angle))
                }
            }
        }
    }
    
    private func dataPolygon(in size: CGSize) -> Path {
        Path { path in
            for (index, value) in data.enumerated() {
                let point = pointOnCircle(
                    center: CGPoint(x: size.width/2, y: size.height/2),
                    radius: size.width/2 * CGFloat(value),
                    angle: angleFor(index: index, total: data.count)
                )
                
                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()
        }
    }
    
    private func angleFor(index: Int, total: Int) -> Double {
        // Start from the top (270° or -90°) and go clockwise
        let angleSize = (2 * Double.pi) / Double(total)
        let startAngle = -(Double.pi / 2) // Top of circle
        return startAngle + angleSize * Double(index)
    }
    
    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        let x = center.x + radius * CGFloat(cos(angle))
        let y = center.y + radius * CGFloat(sin(angle))
        return CGPoint(x: x, y: y)
    }
    
    private func adjustLabelPosition(for point: CGPoint, label: String, angle: Double) -> CGPoint {
        // Estimate text width
        let estimatedWidth = CGFloat(label.count) * 5
        let estimatedHeight: CGFloat = 15
        
        // Adjust position based on which quadrant the label is in
        let degrees = (angle * 180 / .pi).truncatingRemainder(dividingBy: 360)
        
        var adjustedPoint = point
        
        // Top quadrant
        if degrees >= 270 || degrees < 0 {
            adjustedPoint.y -= estimatedHeight/2
        }
        // Right quadrant
        else if degrees >= 0 && degrees < 90 {
            adjustedPoint.x += estimatedWidth/2
        }
        // Bottom quadrant
        else if degrees >= 90 && degrees < 180 {
            adjustedPoint.y += estimatedHeight/2
        }
        // Left quadrant
        else if degrees >= 180 && degrees < 270 {
            adjustedPoint.x -= estimatedWidth/2
        }
        
        return adjustedPoint
    }
}

// Helper extension to calculate emotion metrics from responses and drawing analysis
extension EmotionalMetrics {
    static func calculateFromAssessment(
        responses: [(question: Question, score: Int)],
        drawingAnalysis: String,
        categoryPercentages: [String: Double]
    ) -> EmotionalMetrics {
        // Calculate average score from questionnaire (0-1 scale)
        let avgScore = categoryPercentages.values.reduce(0.0, +) / Double(categoryPercentages.count) / 100.0
        
        // Extract emotional indicators from drawing analysis
        let lowerAnalysis = drawingAnalysis.lowercased()
        
        // Expression level calculation
        var expressionLevel = avgScore
        if lowerAnalysis.contains("expressive") || lowerAnalysis.contains("vibrant") {
            expressionLevel += 0.15
        }
        if lowerAnalysis.contains("detailed") || lowerAnalysis.contains("elaborate") {
            expressionLevel += 0.1
        }
        expressionLevel = min(max(expressionLevel, 0.0), 1.0)
        
        // Emotional balance calculation (higher is more balanced)
        var emotionalBalance = avgScore
        // Adjust based on resilience category if available
        if let resilienceScore = categoryPercentages["Resilience & Coping"] {
            emotionalBalance = (emotionalBalance + (resilienceScore / 100.0)) / 2.0
        }
        if lowerAnalysis.contains("balanced") || lowerAnalysis.contains("harmony") {
            emotionalBalance += 0.1
        }
        if lowerAnalysis.contains("chaotic") || lowerAnalysis.contains("conflicted") {
            emotionalBalance -= 0.1
        }
        emotionalBalance = min(max(emotionalBalance, 0.0), 1.0)
        
        // Creative energy calculation
        var creativeEnergy = 0.5 // Start at neutral
        if lowerAnalysis.contains("creative") || lowerAnalysis.contains("imaginative") {
            creativeEnergy += 0.2
        }
        if lowerAnalysis.contains("colorful") || lowerAnalysis.contains("dynamic") {
            creativeEnergy += 0.15
        }
        if lowerAnalysis.contains("monotone") || lowerAnalysis.contains("rigid") {
            creativeEnergy -= 0.1
        }
        creativeEnergy = min(max(creativeEnergy, 0.0), 1.0)
        
        // Other emotional dimensions
        var joy = 0.5
        if lowerAnalysis.contains("happy") || lowerAnalysis.contains("joy") {
            joy += 0.2
        }
        if lowerAnalysis.contains("sad") || lowerAnalysis.contains("somber") {
            joy -= 0.15
        }
        // Factor in satisfaction scores if available
        if let satisfactionScore = categoryPercentages["Satisfaction & Contentment"] {
            joy = (joy + (satisfactionScore / 100.0)) / 2.0
        }
        joy = min(max(joy, 0.0), 1.0)
        
        var calm = 0.5
        // Adjust based on anxiety scores if available
        if let anxietyScore = categoryPercentages["Anxiety & Stress Management"] {
            calm = 1.0 - (anxietyScore / 100.0) * 0.5 // Invert and scale
        }
        if lowerAnalysis.contains("calm") || lowerAnalysis.contains("peaceful") {
            calm += 0.15
        }
        if lowerAnalysis.contains("anxious") || lowerAnalysis.contains("tense") {
            calm -= 0.15
        }
        calm = min(max(calm, 0.0), 1.0)
        
        var energy = expressionLevel * 0.7 + creativeEnergy * 0.3
        if lowerAnalysis.contains("energetic") || lowerAnalysis.contains("vibrant") {
            energy += 0.1
        }
        if lowerAnalysis.contains("subdued") || lowerAnalysis.contains("low energy") {
            energy -= 0.1
        }
        energy = min(max(energy, 0.0), 1.0)
        
        var tension = 0.5
        if lowerAnalysis.contains("tense") || lowerAnalysis.contains("stress") {
            tension += 0.2
        }
        if lowerAnalysis.contains("relaxed") || lowerAnalysis.contains("ease") {
            tension -= 0.15
        }
        // Factor in stress-related categories
        if let anxietyScore = categoryPercentages["Anxiety & Stress Management"] {
            tension = (tension + (anxietyScore / 100.0) * 0.8) / 2.0
        }
        tension = min(max(tension, 0.0), 1.0)
        
        var expression = expressionLevel * 0.8 + creativeEnergy * 0.2
        if lowerAnalysis.contains("expressive") || lowerAnalysis.contains("communicative") {
            expression += 0.1
        }
        if lowerAnalysis.contains("withdrawn") || lowerAnalysis.contains("reserved") {
            expression -= 0.1
        }
        // Factor in social connection if available
        if let socialScore = categoryPercentages["Social Connection & Loneliness"] {
            expression = (expression + (socialScore / 100.0) * 0.7) / 2.0
        }
        expression = min(max(expression, 0.0), 1.0)
        
        return EmotionalMetrics(
            expressionLevel: expressionLevel,
            emotionalBalance: emotionalBalance,
            creativeEnergy: creativeEnergy,
            joy: joy,
            calm: calm,
            energy: energy,
            tension: tension,
            expression: expression
        )
    }
}
