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
    
    private let networkService = NetworkService()
    
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
    
    func sendMessage(messages: [ChatMessage], model: AIModel) async throws -> String {
        return try await networkService.sendChatMessage(messages: messages, model: model)
    }
    
    func testConnection(liteLLMURL: String) async throws -> Bool {
        return try await networkService.testConnection(liteLLMURL: liteLLMURL)
    }
}