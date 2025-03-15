//
//  AIModel.swift
//  z0miChat
//
//  Created by Aleksey Cherkasskiy on 15.03.2025.
//


import Foundation

struct AIModel: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let provider: ModelProvider
    
    // Custom implementation of Equatable
    static func == (lhs: AIModel, rhs: AIModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.provider == rhs.provider
    }
}

enum ModelProvider: String, Codable {
    case liteLLM = "litellm"
    case openAI = "openai"
    case claude = "anthropic"
    case deepSeek = "deepseek"
    case unknown
    
    var displayName: String {
        switch self {
        case .liteLLM: return "LiteLLM"
        case .openAI: return "OpenAI"
        case .claude: return "Claude"
        case .deepSeek: return "DeepSeek"
        case .unknown: return "Unknown"
        }
    }
}
