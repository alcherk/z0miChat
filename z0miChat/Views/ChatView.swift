//
//  ChatView.swift
//  z0miChat
//
//  Created by Aleksey Cherkasskiy on 15.03.2025.
//

import SwiftUI
import Combine

struct ChatView: View {
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading = false
    @State private var showChatList = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @EnvironmentObject private var modelManager: ModelManager
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var chatHistoryManager: ChatHistoryManager
    @State private var selectedModelId: String = ""
    
    // Notification for retry action
    @State private var retrySubscription: AnyCancellable?
    
    var body: some View {
        VStack {
            // Chat header with model selector and history button
            HStack {
                // Model selector
                Picker("Модель", selection: $selectedModelId) {
                    if modelManager.models.isEmpty {
                        Text("Загрузка моделей...").tag("")
                    } else {
                        ForEach(modelManager.models) { model in
                            Text(model.name).tag(model.id)
                        }
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .disabled(modelManager.models.isEmpty)
                .onChange(of: selectedModelId) { newValue in
                    if !newValue.isEmpty {
                        // Save as last selected model
                        settingsManager.lastSelectedModelId = newValue
                        settingsManager.saveSettings()
                        
                        // Update current session
                        if let currentSession = chatHistoryManager.currentSession, currentSession.modelId != newValue {
                            chatHistoryManager.updateCurrentSession(messages: messages, modelId: newValue)
                        }
                    }
                }
                
                Spacer()
                
                // History button
                Button(action: {
                    showChatList = true
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal)
            
            // Chat title
            if let session = chatHistoryManager.currentSession {
                Text(session.title)
                    .font(.headline)
                    .lineLimit(1)
                    .padding(.horizontal)
            }
            
            // Chat messages
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .onChange(of: messages) { newMessages in
                    if let lastMessage = newMessages.last {
                        withAnimation {
                            scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input area with expandable text field
            HStack(alignment: .bottom) {
                ExpandableTextEditor(text: $messageText, isDisabled: isLoading || selectedModelId.isEmpty)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading || selectedModelId.isEmpty ? .gray : .blue)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading || selectedModelId.isEmpty)
                .padding(.leading, 4)
            }
            .padding()
        }
        .onAppear {
            loadCurrentSession()
            setupRetryHandler()
        }
        .onChange(of: chatHistoryManager.currentSessionId) { _ in
            loadCurrentSession()
        }
        .onChange(of: modelManager.models) { newModels in
            if !newModels.isEmpty && selectedModelId.isEmpty {
                selectedModelId = newModels.first?.id ?? ""
            }
        }
        .sheet(isPresented: $showChatList) {
            NavigationView {
                ChatListView()
                    .environmentObject(chatHistoryManager)
            }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Ошибка"),
                message: Text(errorMessage ?? "Произошла неизвестная ошибка"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func loadCurrentSession() {
        guard let currentSession = chatHistoryManager.currentSession else {
            // Create a new session if none exists
            let newSession = chatHistoryManager.createNewSession()
            messages = newSession.messages
            selectedModelId = newSession.modelId
            return
        }
        
        messages = currentSession.messages
        
        // Check if the session has a model ID
        if !currentSession.modelId.isEmpty {
            selectedModelId = currentSession.modelId
        }
        // If not, check if we have a last selected model
        else if !settingsManager.lastSelectedModelId.isEmpty && modelManager.models.contains(where: { $0.id == settingsManager.lastSelectedModelId }) {
            selectedModelId = settingsManager.lastSelectedModelId
            chatHistoryManager.updateCurrentSession(messages: messages, modelId: selectedModelId)
        }
        // If no last selected model, use the first available model
        else if !modelManager.models.isEmpty {
            selectedModelId = modelManager.models.first?.id ?? ""
            chatHistoryManager.updateCurrentSession(messages: messages, modelId: selectedModelId)
        }
    }
    
    // Setup notification handler for retry button
    private func setupRetryHandler() {
        retrySubscription = NotificationCenter.default
            .publisher(for: Notification.Name("RetryLastUserMessage"))
            .sink { _ in
                self.retryLastUserMessage()
            }
    }
    
    // Find and retry last user message
    private func retryLastUserMessage() {
        // Find the last system error message
        if let errorIndex = messages.lastIndex(where: { $0.role == .system && $0.content.hasPrefix("Ошибка:") }) {
            // Remove the error message
            messages.remove(at: errorIndex)
            
            // Find the last user message before the error
            if let lastUserMessageIndex = messages.lastIndex(where: { $0.role == .user }) {
                let userMessage = messages[lastUserMessageIndex]
                
                // Remove any assistant messages that might be after this user message
                // (there typically shouldn't be any if there was an error)
                while messages.count > lastUserMessageIndex + 1 {
                    messages.remove(at: lastUserMessageIndex + 1)
                }
                
                // Start loading and update chat history
                isLoading = true
                chatHistoryManager.updateCurrentSession(messages: messages, modelId: selectedModelId)
                
                // Retry sending the message
                Task {
                    do {
                        guard let selectedModel = modelManager.models.first(where: { $0.id == selectedModelId }) else {
                            throw NSError(domain: "ChatError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Выбранная модель не найдена"])
                        }
                        
                        let response = try await modelManager.sendChatMessage(
                            messages: messages,
                            model: selectedModel
                        )
                        
                        await MainActor.run {
                            // Create assistant message with content and reasoning if available
                            let assistantMessage = ChatMessage(
                                role: .assistant,
                                content: response.content,
                                reasoning: response.reasoning
                            )
                            messages.append(assistantMessage)
                            isLoading = false
                            
                            // Update chat history with the response
                            chatHistoryManager.updateCurrentSession(messages: messages, modelId: selectedModelId)
                        }
                    } catch {
                        await MainActor.run {
                            // Show error alert with retry option
                            errorMessage = error.localizedDescription
                            showErrorAlert = true
                            isLoading = false
                            
                            // Add system error message to chat with retry button
                            let errorContent = "Ошибка: \(error.localizedDescription)"
                            let errorMsg = ChatMessage(role: .system, content: errorContent)
                            messages.append(errorMsg)
                            
                            // Save the state with error message
                            chatHistoryManager.updateCurrentSession(messages: messages, modelId: selectedModelId)
                        }
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, !selectedModelId.isEmpty else { return }
        
        let userMessage = ChatMessage(role: .user, content: trimmedText)
        messages.append(userMessage)
        messageText = ""
        isLoading = true
        
        // Update chat history
        chatHistoryManager.updateCurrentSession(messages: messages, modelId: selectedModelId)
        
        Task {
            do {
                guard let selectedModel = modelManager.models.first(where: { $0.id == selectedModelId }) else {
                    throw NSError(domain: "ChatError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Выбранная модель не найдена"])
                }
                
                let response = try await modelManager.sendChatMessage(
                    messages: messages,
                    model: selectedModel
                )
                
                await MainActor.run {
                    // Create assistant message with content and reasoning if available
                    let assistantMessage = ChatMessage(
                        role: .assistant,
                        content: response.content,
                        reasoning: response.reasoning
                    )
                    messages.append(assistantMessage)
                    isLoading = false
                    
                    // Update chat history with the response
                    chatHistoryManager.updateCurrentSession(messages: messages, modelId: selectedModelId)
                }
            } catch {
                await MainActor.run {
                    // Show error alert with retry option
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                    isLoading = false
                    
                    // Add system error message to chat with retry button
                    let errorContent = "Ошибка: \(error.localizedDescription)"
                    let errorMsg = ChatMessage(role: .system, content: errorContent)
                    messages.append(errorMsg)
                    
                    // Save the state with error message
                    chatHistoryManager.updateCurrentSession(messages: messages, modelId: selectedModelId)
                }
            }
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
            .environmentObject(ModelManager(settingsManager: SettingsManager()))
            .environmentObject(SettingsManager())
            .environmentObject(ChatHistoryManager(settingsManager: SettingsManager()))
    }
}
