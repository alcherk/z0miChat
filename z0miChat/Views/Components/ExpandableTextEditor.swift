//
//  ExpandableTextEditor.swift
//  z0miChat
//
//  Created by Aleksey Cherkasskiy on 15.03.2025.
//

import SwiftUI

struct ExpandableTextEditor: View {
    @Binding var text: String
    var isDisabled: Bool
    
    // Set fixed heights
    private let minHeight: CGFloat = 40
    private let maxHeight: CGFloat = 120 // Approximately 5 lines
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder
            if text.isEmpty {
                Text("Напишите сообщение...")
                    .foregroundColor(Color(.placeholderText))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
                    .allowsHitTesting(false)
            }
            
            // Simple TextEditor with fixed frame and scroll
            TextEditor(text: $text)
                .frame(minHeight: minHeight, maxHeight: maxHeight)
                .fixedSize(horizontal: false, vertical: true)
                .background(Color.clear)
                .scrollContentBackground(.hidden)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .disabled(isDisabled)
                .opacity(text.isEmpty ? 0.7 : 1)
        }
    }
}

// Multiline TextField
extension TextField {
    func lineLimit(_ lineLimit: Int) -> some View {
        self.fixedSize(horizontal: false, vertical: true)
    }
}

struct ExpandableTextEditor_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ExpandableTextEditor(text: .constant("Test message"), isDisabled: false)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(20)
            
            ExpandableTextEditor(text: .constant("This is a longer message that should cause the text editor to expand vertically to accommodate multiple lines of text input from the user."), isDisabled: false)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(20)
        }
        .padding()
    }
}
