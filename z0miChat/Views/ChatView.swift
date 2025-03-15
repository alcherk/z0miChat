//
//  ChatView.swift
//  z0miChat
//
//  Created by Aleksey Cherkasskiy on 15.03.2025.
//

import SwiftUI

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
            
            // Input area
            HStack {
                TextField("Напишите сообщение...", text: $messageText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .disabled(isLoading || selectedModelId.isEmpty)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading || selectedModelId.isEmpty ? .gray : .blue)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading || selectedModelId.isEmpty)
            }
            .padding()
        }
        .onAppear {
            loadCurrentSession()
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
                
                let response = try await modelManager.sendMessage(
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
                    // Show error alert instead of adding error message to chat
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                    isLoading = false
                    
                    // When error occurs, prevent unfinished messages
                    // from being saved by reverting to the previous state
                    loadCurrentSession()
                }
            }
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
            .environmentObject(ModelManager())
            .environmentObject(SettingsManager())
            .environmentObject(ChatHistoryManager())
    }
}
