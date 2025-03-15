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
                    if let currentSession = chatHistoryManager.currentSession, currentSession.modelId != newValue {
                        chatHistoryManager.updateCurrentSession(messages: messages, modelId: newValue)
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
        selectedModelId = currentSession.modelId
        
        // If modelId is empty but we have models available, set the first model
        if selectedModelId.isEmpty && !modelManager.models.isEmpty {
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
                    let assistantMessage = ChatMessage(role: .assistant, content: response)
                    messages.append(assistantMessage)
                    isLoading = false
                    
                    // Update chat history with the response
                    chatHistoryManager.updateCurrentSession(messages: messages, modelId: selectedModelId)
                }
            } catch {
                await MainActor.run {
                    let errorMessage = ChatMessage(role: .system, content: "Ошибка: \(error.localizedDescription)")
                    messages.append(errorMessage)
                    isLoading = false
                    
                    // Update chat history with the error
                    chatHistoryManager.updateCurrentSession(messages: messages, modelId: selectedModelId)
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
