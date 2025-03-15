//
//  NetworkService.swift
//  z0miChat
//
//  Created by Aleksey Cherkasskiy on 15.03.2025.
//

import Foundation
import UIKit

class NetworkService {
    private let session = URLSession.shared
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()
    
    private let settingsManager: SettingsManager
    
    // Enable verbose logging
    private let debugLogging = true
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }
    
    func fetchModels() async throws -> [AIModel] {
        let settingsManager = SettingsManager()
        guard !settingsManager.liteLLMURL.isEmpty else {
            // Return empty array if no server URL is set
            return []
        }
        
        let baseURL = settingsManager.liteLLMURL
        guard let url = URL(string: "\(baseURL)/v1/models") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authentication headers
        if !settingsManager.liteLLMKey.isEmpty {
            request.setValue("Bearer \(settingsManager.liteLLMKey)", forHTTPHeaderField: "Authorization")
        }
        
        logRequest(request)
        
        let (data, response) = try await session.data(for: request)
        logResponse(response, data: data)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // Parse the response
        struct ModelsResponse: Decodable {
            let data: [ModelData]
            
            struct ModelData: Decodable {
                let id: String
                let owned_by: String?
            }
        }
        
        let modelsResponse = try jsonDecoder.decode(ModelsResponse.self, from: data)
        
        // Log decoded model data
        if debugLogging {
            print("🤖 Parsed models: \(modelsResponse.data.count)")
            for model in modelsResponse.data {
                print("  - \(model.id) (owner: \(model.owned_by ?? "unknown"))")
            }
        }
        
        // Map to our model type
        return modelsResponse.data.map { modelData in
            let provider: ModelProvider
            let name: String
            
            if modelData.id.contains("gpt") {
                provider = .openAI
                name = modelData.id
            } else if modelData.id.contains("claude") {
                provider = .claude
                name = modelData.id
            } else if modelData.id.contains("deepseek") {
                provider = .deepSeek
                name = modelData.id
            } else {
                provider = .unknown
                name = modelData.id
            }
            
            return AIModel(id: modelData.id, name: name, provider: provider)
        }
    }
    
    func sendChatMessage(messages: [ChatMessage], model: AIModel) async throws -> (content: String, reasoning: String?) {
            let settingsManager = SettingsManager()
            guard !settingsManager.liteLLMURL.isEmpty else {
                throw NSError(domain: "NetworkError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Server URL not configured"])
            }
            
            let baseURL = settingsManager.liteLLMURL
            guard let url = URL(string: "\(baseURL)/v1/chat/completions") else {
                throw URLError(.badURL)
            }
            
            // Create request body
            struct ChatRequest: Encodable {
                let model: String
                let messages: [Message]
                let temperature: Double
                let responseFormat: ResponseFormat?
                
                struct Message: Encodable {
                    let role: String
                    let content: String
                }
                
                struct ResponseFormat: Encodable {
                    let type: String
                    let includeReasoning: Bool?
                }
            }
            
            // Process messages based on model requirements
            var processedMessages = messages
            
            // General message history management for all models
            // If conversation is very long, we'll truncate it to prevent timeouts
            if processedMessages.count > 20 {
                // Save important system messages
                let systemMessages = processedMessages.filter { $0.role == .system }
                
                // Keep only most recent history
                // More aggressive truncation if we've experienced timeouts before
                let keepCount = 12
                processedMessages = Array(processedMessages.suffix(keepCount))
                
                // Add system context message about truncation
                processedMessages.insert(ChatMessage(
                    role: .system,
                    content: "История беседы была сокращена. Отображаются только последние \(keepCount) сообщений."
                ), at: 0)
                
                // Add back important system messages
                if !systemMessages.isEmpty {
                    processedMessages.insert(contentsOf: systemMessages, at: 0)
                }
            }
            
            // Special handling for deepseek models which require strict user/assistant alternation
            if model.id.contains("deepseek") {
                // Filter out system messages for processing
                var filteredMessages = processedMessages.filter { $0.role != .system }
                
                // Ensure strict alternation for user/assistant messages
                if filteredMessages.count > 1 {
                    var processedFiltered: [ChatMessage] = []
                    var currentRole = filteredMessages[0].role
                    var combinedContent = filteredMessages[0].content
                    
                    // Combine consecutive messages of the same role
                    for i in 1..<filteredMessages.count {
                        let message = filteredMessages[i]
                        
                        if message.role == currentRole {
                            // Same role - combine content
                            combinedContent += "\n\n" + message.content
                        } else {
                            // Different role - add previous combined message and start new one
                            processedFiltered.append(ChatMessage(
                                role: currentRole,
                                content: combinedContent
                            ))
                            currentRole = message.role
                            combinedContent = message.content
                        }
                    }
                    
                    // Add the last combined message
                    processedFiltered.append(ChatMessage(
                        role: currentRole,
                        content: combinedContent
                    ))
                    
                    // For Deepseek, ensure we start with a user message and end with a user message
                    if processedFiltered.first?.role != .user {
                        // Insert a dummy user message if needed
                        processedFiltered.insert(ChatMessage(
                            role: .user,
                            content: "Инициализация чата."
                        ), at: 0)
                    }
                    
                    // Limit the conversation history to avoid timeouts
                    // Keep only the last few messages if history is too long
                    if processedFiltered.count > 10 {
                        let systemMsg = ChatMessage(
                            role: .system,
                            content: "Предыдущая часть беседы была пропущена для оптимизации запроса."
                        )
                        
                        // Keep last 8 messages (4 user-assistant exchanges)
                        processedFiltered = Array(processedFiltered.suffix(8))
                        processedFiltered.insert(systemMsg, at: 0)
                    }
                    
                    // Replace processed messages with the alternating ones
                    processedMessages = processedFiltered
                    
                    // Add back system messages at the beginning
                    let systemMessages = messages.filter { $0.role == .system }
                    if !systemMessages.isEmpty {
                        processedMessages.insert(contentsOf: systemMessages, at: 0)
                    }
                }
            }
            
            // Map to request format and log processed messages
            let requestMessages = processedMessages.map { ChatRequest.Message(role: $0.role.rawValue, content: $0.content) }
            
            // Log the processed messages for debugging
            if debugLogging && model.id.contains("deepseek") {
                print("🧠 Processed messages for \(model.id):")
                for (i, msg) in processedMessages.enumerated() {
                    print("  \(i): \(msg.role.rawValue) - \(msg.content.prefix(30))...")
                }
            }
        
            // Add reasoning request for models that support it
            let responseFormat: ChatRequest.ResponseFormat?
            if model.id.contains("claude") || model.id.contains("deepseek") {
                responseFormat = ChatRequest.ResponseFormat(type: "json", includeReasoning: true)
            } else {
                responseFormat = nil
            }
            
            let chatRequest = ChatRequest(
                model: model.id,
                messages: requestMessages,
                temperature: 0.7,
                responseFormat: responseFormat
            )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication headers based on the model provider
        if !settingsManager.liteLLMKey.isEmpty {
            request.setValue("Bearer \(settingsManager.liteLLMKey)", forHTTPHeaderField: "Authorization")
        }
        
        // Add provider-specific API keys as headers
        switch model.provider {
        case .openAI:
            if !settingsManager.openAIKey.isEmpty {
                request.setValue(settingsManager.openAIKey, forHTTPHeaderField: "X-OpenAI-Api-Key")
            }
        case .claude:
            if !settingsManager.claudeKey.isEmpty {
                request.setValue(settingsManager.claudeKey, forHTTPHeaderField: "X-Anthropic-Api-Key")
            }
        case .deepSeek:
            if !settingsManager.deepSeekKey.isEmpty {
                request.setValue(settingsManager.deepSeekKey, forHTTPHeaderField: "X-DeepSeek-Api-Key")
            }
        default:
            break
        }
        
        request.httpBody = try jsonEncoder.encode(chatRequest)
        logRequest(request)
        
        let (data, response) = try await session.data(for: request)
        logResponse(response, data: data)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // Parse response
        struct ChatResponse: Decodable {
            let choices: [Choice]
            let usage: Usage?
            let reasoning: String?  // Some models may include reasoning directly
            let reasoning_content: String?  // Additional field for reasoning content
            
            struct Choice: Decodable {
                let message: Message
                let index: Int?
                let finish_reason: String?
                
                struct Message: Decodable {
                    let role: String
                    let content: String
                    let reasoning: String?  // Field for model reasoning/thinking
                    let reasoning_content: String?  // Additional field for reasoning content
                }
            }
            
            struct Usage: Decodable {
                let prompt_tokens: Int?
                let completion_tokens: Int?
                let total_tokens: Int?
            }
        }
        
        let chatResponse = try jsonDecoder.decode(ChatResponse.self, from: data)
        
        guard let firstChoice = chatResponse.choices.first else {
            throw NSError(domain: "ChatError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No response received"])
        }
        
        // Extract reasoning either from the message or top-level property,
        // or try reasoning_content as a fallback
        let reasoning = firstChoice.message.reasoning ??
                        chatResponse.reasoning ??
                        firstChoice.message.reasoning_content ??
                        chatResponse.reasoning_content
        
        // Use the message content as the response
        return (firstChoice.message.content, reasoning)
    }
    
    func testConnection(liteLLMURL: String) async throws -> Bool {
        guard !liteLLMURL.isEmpty else {
            throw NSError(domain: "NetworkError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Server URL not configured"])
        }
        
        guard let url = URL(string: "\(liteLLMURL)/v1/models") else {
            throw URLError(.badURL)
        }
        
        let settingsManager = SettingsManager()
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if !settingsManager.liteLLMKey.isEmpty {
            request.setValue("Bearer \(settingsManager.liteLLMKey)", forHTTPHeaderField: "Authorization")
        }
        
        logRequest(request)
        
        let (data, response) = try await session.data(for: request)
        logResponse(response, data: data)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }
        
        return httpResponse.statusCode == 200
    }
    
    // MARK: - Logging Helpers
    
    private func logRequest(_ request: URLRequest) {
        guard debugLogging else { return }
        
        print("\n📤 REQUEST: \(request.httpMethod ?? "Unknown") \(request.url?.absoluteString ?? "Unknown URL")")
        
        // Log headers (hiding sensitive values)
        print("📋 Headers:")
        if let headers = request.allHTTPHeaderFields {
            for (key, value) in headers {
                if key.lowercased().contains("api-key") || key.lowercased() == "authorization" {
                    print("  \(key): ********")
                } else {
                    print("  \(key): \(value)")
                }
            }
        }
        
        // Log body if exists
        if let httpBody = request.httpBody, let bodyString = String(data: httpBody, encoding: .utf8) {
            print("📦 Body: \(bodyString)")
        }
    }
    
    private func logResponse(_ response: URLResponse, data: Data) {
        guard debugLogging else { return }
        
        if let httpResponse = response as? HTTPURLResponse {
            print("\n📥 RESPONSE: Status \(httpResponse.statusCode) from \(response.url?.absoluteString ?? "Unknown URL")")
            
            // Log headers
            print("📋 Headers:")
            for (key, value) in httpResponse.allHeaderFields {
                print("  \(key): \(value)")
            }
            
            // Try to format the response based on content type
            if let contentType = httpResponse.allHeaderFields["Content-Type"] as? String {
                if contentType.contains("application/json") {
                    // Pretty print JSON
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                       let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
                       let prettyString = String(data: prettyData, encoding: .utf8) {
                        print("📦 Response Body (JSON):\n\(prettyString)")
                    } else {
                        if let string = String(data: data, encoding: .utf8) {
                            print("📦 Response Body:\n\(string)")
                        }
                    }
                } else if contentType.contains("text/") {
                    if let string = String(data: data, encoding: .utf8) {
                        print("📦 Response Body (Text):\n\(string)")
                    }
                } else {
                    print("📦 Response Body: \(data.count) bytes of \(contentType)")
                }
            } else {
                // Try to decode as text, but don't assume it's text
                if let string = String(data: data, encoding: .utf8) {
                    print("📦 Response Body:\n\(string)")
                } else {
                    print("📦 Response Body: \(data.count) bytes of binary data")
                }
            }
        } else {
            print("\n📥 RESPONSE: Non-HTTP response from \(response.url?.absoluteString ?? "Unknown URL")")
        }
        
        print("-----------------------------------")
    }
}
