//
//  MessageBubble.swift
//  z0miChat
//
//  Created by Aleksey Cherkasskiy on 15.03.2025.
//


import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
                Text(message.content)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .cornerRadius(16, corners: [.topLeft, .topRight, .bottomLeft])
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    if message.role == .system {
                        Text("System")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text(message.role.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if message.role == .assistant {
                        // Use MarkdownTextView for assistant messages
                        MarkdownTextView(text: message.content)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
                    } else {
                        // Use regular Text for non-assistant messages
                        Text(message.content)
                            .padding(12)
                            .background(message.role == .system ? Color.orange.opacity(0.2) : Color(.systemGray6))
                            .foregroundColor(message.role == .system ? .orange : .primary)
                            .cornerRadius(16)
                            .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
                    }
                }
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

struct MessageBubble_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MessageBubble(message: ChatMessage(role: .user, content: "Hello, how are you?"))
            MessageBubble(message: ChatMessage(role: .assistant, content: "I'm doing well, thanks for asking!"))
            MessageBubble(message: ChatMessage(role: .assistant, content: "Here's some **bold text** and *italic text*.\n\n```swift\nlet x = 10\n```"))
            MessageBubble(message: ChatMessage(role: .system, content: "Error: Connection failed"))
        }
        .padding()
    }
}
