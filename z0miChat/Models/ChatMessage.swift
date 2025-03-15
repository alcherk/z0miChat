//
//  ChatMessage.swift
//  z0miChat
//
//  Created by Aleksey Cherkasskiy on 15.03.2025.
//

import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    var id: UUID
    let role: MessageRole
    let content: String
    let reasoning: String?  // Added field for model reasoning/thinking
    var timestamp: Date
    
    init(id: UUID = UUID(), role: MessageRole, content: String, reasoning: String? = nil, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.reasoning = reasoning
        self.timestamp = timestamp
    }
    
    // Custom implementation of Equatable
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.role == rhs.role &&
        lhs.content == rhs.content &&
        lhs.reasoning == rhs.reasoning
    }
}

enum MessageRole: String, Codable {
    case system
    case user
    case assistant
}
