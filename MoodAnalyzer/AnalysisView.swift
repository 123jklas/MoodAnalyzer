//
//  AnalysisView.swift
//  MoodAnalyzer
//
//  Created by Srimoyee Mukhopadhyay on 3/1/25.
//
//
//  AnalysisView.swift
//  MoodAnalyzer
//
//  Created on 3/1/25.
//

import SwiftUI

struct AnalysisView: View {
    let analysisText: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Spacer()
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing)
                }
                
                Text("Drawing Analysis")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                // Divider line
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(.blue)
                    .padding(.horizontal)
                
                Text(analysisText)
                    .font(.body)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.systemGray6))
                    )
                    .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    // Return to main screen
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding()
            }
            .padding(.top)
        }
    }
}

struct AnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        AnalysisView(analysisText: "This drawing shows a balanced composition with strong use of color. The lines indicate confidence and emotional stability, while the spatial arrangement suggests openness to new experiences. The drawing style reflects a creative mindset with attention to detail.")
    }
}
