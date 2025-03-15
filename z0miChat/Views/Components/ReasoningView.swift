//
//  ReasoningView.swift
//  z0miChat
//
//  Created by Aleksey Cherkasskiy on 15.03.2025.
//

import SwiftUI

struct ReasoningView: View {
    let reasoning: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Expand/collapse button
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Размышления")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Reasoning content
            if isExpanded {
                MarkdownTextView(text: reasoning)
                    .font(.callout)
                    .padding(.top, 2)
                    .transition(.opacity)
            }
        }
        .padding(8)
        .background(Color.purple.opacity(0.7))
        .cornerRadius(8)
    }
}

struct ReasoningView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ReasoningView(reasoning: "Этот пример показывает, как я анализировал вопрос. Сначала я рассмотрел концепцию X, затем применил принцип Y. Из этого я сделал вывод Z.")
                .previewLayout(.sizeThatFits)
                .padding()
            
            ReasoningView(reasoning: "Более сложный пример с *форматированием* и **акцентированием** важных моментов.\n\n```swift\nlet code = \"пример кода\"\n```")
                .previewLayout(.sizeThatFits)
                .padding()
        }
    }
}
