//
//  ChatMessage.swift
//  z0miChat
//
//  Created by Aleksey Cherkasskiy on 15.03.2025.
//


import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp = Date()
    
    // Custom implementation of Equatable
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.role == rhs.role &&
        lhs.content == rhs.content
    }
}

enum MessageRole: String, Codable {
    case system
    case user
    case assistant
}
