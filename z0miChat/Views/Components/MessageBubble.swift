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
                        VStack(alignment: .leading, spacing: 8) {
                            // Show reasoning block at the top if available
                            if let reasoning = message.reasoning, !reasoning.isEmpty {
                                ReasoningView(reasoning: reasoning)
                                    .padding(.horizontal, 8)
                                    .padding(.top, 8)
                            }
                            
                            // Main message content below reasoning
                            MarkdownTextView(text: message.content)
                                .padding(12)
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
                    } else {
                        // Use regular Text for non-assistant messages
                        VStack(alignment: .leading, spacing: 4) {
                            Text(message.content)
                                .padding(12)
                                .background(message.role == .system ? Color.orange.opacity(0.2) : Color(.systemGray6))
                                .foregroundColor(message.role == .system ? .orange : .primary)
                                .cornerRadius(16)
                                .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
                            
                            // Add retry button for system error messages
                            if message.role == .system && message.content.hasPrefix("Ошибка:") {
                                Button(action: {
                                    // Use NotificationCenter to broadcast the retry action
                                    NotificationCenter.default.post(
                                        name: Notification.Name("RetryLastUserMessage"),
                                        object: message.id
                                    )
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                        Text("Повторить последний запрос")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                }
                            }
                        }
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
            MessageBubble(message: ChatMessage(role: .assistant, content: "Here's some **bold text** and *italic text*.\n\n```swift\nlet x = 10\n```", reasoning: "This response shows formatting examples using Markdown syntax. I'm including both text formatting and a code block."))
            MessageBubble(message: ChatMessage(role: .system, content: "Error: Connection failed"))
        }
        .padding()
    }
}
