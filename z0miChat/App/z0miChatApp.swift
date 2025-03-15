//
//  z0miChatApp.swift
//  z0miChat
//
//  Created by Aleksey Cherkasskiy on 15.03.2025.
//

import SwiftUI

@main
struct AIChatApp: App {
    @StateObject private var modelManager = ModelManager()
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var chatHistoryManager = ChatHistoryManager()
    
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
