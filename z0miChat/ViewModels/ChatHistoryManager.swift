//
//  ChatHistoryManager.swift
//  z0miChat
//
//  Created by Aleksey Cherkasskiy on 15.03.2025.
//

import Foundation
import Combine
import UIKit

class ChatHistoryManager: ObservableObject {
    @Published var sessions: [ChatSession] = []
    @Published var currentSessionId: UUID?
    
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "chatSessions"
    private let currentSessionKey = "currentSessionId"
    private let settingsManager: SettingsManager
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        loadSessions()
        
        // If there's no current session, create one
        if currentSessionId == nil || !sessions.contains(where: { $0.id == currentSessionId }) {
            createNewSession()
        }
    }
    
    var currentSession: ChatSession? {
        get {
            guard let id = currentSessionId else { return nil }
            return sessions.first { $0.id == id }
        }
        set {
            guard let newValue = newValue else { return }
            
            // Update existing session if it exists
            if let index = sessions.firstIndex(where: { $0.id == newValue.id }) {
                sessions[index] = newValue
            }
            
            saveSessions()
        }
    }
    
    func loadSessions() {
        // Load sessions
        if let data = userDefaults.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([ChatSession].self, from: data) {
            sessions = decoded
        }
        
        // Load current session ID
        if let idString = userDefaults.string(forKey: currentSessionKey),
           let id = UUID(uuidString: idString) {
            currentSessionId = id
        }
    }
    
    func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            userDefaults.set(encoded, forKey: sessionsKey)
        }
        
        // Save current session ID
        if let id = currentSessionId {
            userDefaults.set(id.uuidString, forKey: currentSessionKey)
        }
    }
    
    func createNewSession() -> ChatSession {
        var newSession = ChatSession()
        
        // Set the model ID to the last selected model if available
        if !settingsManager.lastSelectedModelId.isEmpty {
            newSession.modelId = settingsManager.lastSelectedModelId
        }
        
        sessions.insert(newSession, at: 0) // Add to the beginning of the list
        currentSessionId = newSession.id
        saveSessions()
        return newSession
    }
    

    
    func switchToSession(with id: UUID) {
        currentSessionId = id
        saveSessions()
    }
    
    func updateCurrentSession(messages: [ChatMessage], modelId: String) {
        guard var session = currentSession else { return }
        
        session.messages = messages
        session.modelId = modelId
        session.lastUpdatedAt = Date()
        session.updateTitleFromContent()
        
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        }
        
        saveSessions()
    }
    
    func deleteSession(with id: UUID) {
        sessions.removeAll { $0.id == id }
        
        // If we deleted the current session, select another one or create a new one
        if currentSessionId == id {
            if let firstSession = sessions.first {
                currentSessionId = firstSession.id
            } else {
                createNewSession()
            }
        }
        
        saveSessions()
    }
    
    func renameSession(id: UUID, newTitle: String) {
        guard var session = sessions.first(where: { $0.id == id }) else { return }
        
        session.title = newTitle
        
        if let index = sessions.firstIndex(where: { $0.id == id }) {
            sessions[index] = session
        }
        
        saveSessions()
    }
}
