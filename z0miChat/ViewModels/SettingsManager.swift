//
//  SettingsManager.swift
//  z0miChat
//
//  Created by Aleksey Cherkasskiy on 15.03.2025.
//


import Foundation
import Combine

class SettingsManager: ObservableObject {
    @Published var liteLLMURL: String = ""
    @Published var liteLLMKey: String = ""
    @Published var openAIKey: String = ""
    @Published var claudeKey: String = ""
    @Published var deepSeekKey: String = ""
    @Published var lastSelectedModelId: String = ""
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadSettings()
    }
    
    func saveSettings() {
        userDefaults.set(liteLLMURL, forKey: "liteLLMURL")
        userDefaults.set(lastSelectedModelId, forKey: "lastSelectedModelId")
        
        // Securely store API keys in keychain
        KeychainManager.save(key: "liteLLMKey", data: liteLLMKey)
        KeychainManager.save(key: "openAIKey", data: openAIKey)
        KeychainManager.save(key: "claudeKey", data: claudeKey)
        KeychainManager.save(key: "deepSeekKey", data: deepSeekKey)
    }
    
    func loadSettings() {
        liteLLMURL = userDefaults.string(forKey: "liteLLMURL") ?? ""
        lastSelectedModelId = userDefaults.string(forKey: "lastSelectedModelId") ?? ""
        
        // Load API keys from keychain
        liteLLMKey = KeychainManager.load(key: "liteLLMKey") ?? ""
        openAIKey = KeychainManager.load(key: "openAIKey") ?? ""
        claudeKey = KeychainManager.load(key: "claudeKey") ?? ""
        deepSeekKey = KeychainManager.load(key: "deepSeekKey") ?? ""
    }
}
