//
//  ChatSession.swift
//  z0miChat
//
//  Created by Aleksey Cherkasskiy on 15.03.2025.
//


import Foundation

struct ChatSession: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var messages: [ChatMessage]
    var modelId: String
    var createdAt: Date
    var lastUpdatedAt: Date
    
    init(id: UUID = UUID(), title: String = "Новый чат", messages: [ChatMessage] = [], modelId: String = "", createdAt: Date = Date(), lastUpdatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.messages = messages
        self.modelId = modelId
        self.createdAt = createdAt
        self.lastUpdatedAt = lastUpdatedAt
    }
    
    // Generate a title based on the first message if title is empty or default
    mutating func updateTitleFromContent() {
        if title == "Новый чат" || title.isEmpty {
            if let firstUserMessage = messages.first(where: { $0.role == .user })?.content {
                // Use the first 50 characters of the first user message as the title
                let truncatedTitle = firstUserMessage.prefix(50)
                
                if truncatedTitle.count < firstUserMessage.count {
                    title = "\(truncatedTitle)..."
                } else {
                    title = String(truncatedTitle)
                }
            }
        }
    }
    
    // Equatable implementation
    static func == (lhs: ChatSession, rhs: ChatSession) -> Bool {
        lhs.id == rhs.id
    }
}