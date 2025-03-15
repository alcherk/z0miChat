//
//  ModelManager.swift
//  z0miChat
//
//  Created by Aleksey Cherkasskiy on 15.03.2025.
//

import Foundation
import Combine

class ModelManager: ObservableObject {
    @Published var models: [AIModel] = []
    @Published var isLoading = false
    
    private let networkService: NetworkService
    
    init(settingsManager: SettingsManager) {
        self.networkService = NetworkService(settingsManager: settingsManager)
    }
    
    func fetchAvailableModels() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let models = try await networkService.fetchModels()
            
            await MainActor.run {
                self.models = models
                isLoading = false
            }
        } catch {
            print("Error fetching models: \(error.localizedDescription)")
            
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    // Change the function name to create a new clean implementation
    func sendChatMessage(messages: [ChatMessage], model: AIModel) async throws -> (content: String, reasoning: String?) {
        return try await networkService.sendChatMessage(messages: messages, model: model)
    }
    
    func testConnection(liteLLMURL: String) async throws -> Bool {
        return try await networkService.testConnection(liteLLMURL: liteLLMURL)
    }
    
    // Helper method to check if a model supports reasoning/thinking
    func modelSupportsReasoning(model: AIModel) -> Bool {
        // Models that are known to support reasoning
        let modelsWithReasoning = [
            // Claude models
            "claude-3-opus",
            "claude-3-sonnet",
            "claude-3-haiku",
            "claude-3.5-sonnet",
            // DeepSeek models
            "deepseek-chat",
            "deepseek-coder",
            "deepseek-llm",
            "deepseek/deepseek-reasoner"
        ]
        
        return modelsWithReasoning.contains { model.id.contains($0) }
    }
}
