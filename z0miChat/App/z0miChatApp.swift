//
//  z0miChatApp.swift
//  z0miChat
//
//  Created by Aleksey Cherkasskiy on 15.03.2025.
//

import SwiftUI

@main
struct AIChatApp: App {
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var modelManager: ModelManager
    @StateObject private var chatHistoryManager: ChatHistoryManager
    
    init() {
        // Use self-initializing for StateObjects
        let settings = SettingsManager()
        _settingsManager = StateObject(wrappedValue: settings)
        _modelManager = StateObject(wrappedValue: ModelManager(settingsManager: settings))
        _chatHistoryManager = StateObject(wrappedValue: ChatHistoryManager(settingsManager: settings))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(modelManager)
                .environmentObject(settingsManager)
                .environmentObject(chatHistoryManager)
                .onAppear {
                    Task {
                        await modelManager.fetchAvailableModels()
                    }
                }
        }
    }
}
