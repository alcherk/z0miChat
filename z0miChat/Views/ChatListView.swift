//
//  ChatListView.swift
//  z0miChat
//
//  Created by Aleksey Cherkasskiy on 15.03.2025.
//


import SwiftUI

struct ChatListView: View {
    @EnvironmentObject private var chatHistoryManager: ChatHistoryManager
    @Environment(\.presentationMode) var presentationMode
    @State private var editingSessionId: UUID?
    @State private var newTitle: String = ""
    
    var body: some View {
        List {
            // New chat button
            Button(action: {
                let _ = chatHistoryManager.createNewSession()
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(.blue)
                    Text("Новый чат")
                        .fontWeight(.medium)
                }
            }
            .padding(.vertical, 8)
            
            // Divider
            Divider()
                .padding(.vertical, 4)
            
            // List of previous chats
            ForEach(chatHistoryManager.sessions) { session in
                Button(action: {
                    chatHistoryManager.switchToSession(with: session.id)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(session.title)
                                .fontWeight(chatHistoryManager.currentSessionId == session.id ? .bold : .regular)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Text(formatDate(session.lastUpdatedAt))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Only show the edit button if this is not the currently selected session
                        if chatHistoryManager.currentSessionId != session.id {
                            Button(action: {
                                editingSessionId = session.id
                                newTitle = session.title
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
                .background(chatHistoryManager.currentSessionId == session.id ? Color.gray.opacity(0.2) : Color.clear)
                .cornerRadius(8)
            }
            .onDelete { indexSet in
                let sessionsToDelete = indexSet.map { chatHistoryManager.sessions[$0] }
                for session in sessionsToDelete {
                    chatHistoryManager.deleteSession(with: session.id)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("История чатов")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        .alert(item: Binding(
            get: { editingSessionId.flatMap { id in chatHistoryManager.sessions.first(where: { $0.id == id }) } },
            set: { session in editingSessionId = session?.id }
        )) { session in
            Alert(
                title: Text("Переименовать чат"),
                message: Text("Введите новое название для чата"),
                primaryButton: .default(Text("Сохранить")) {
                    if !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        chatHistoryManager.renameSession(id: session.id, newTitle: newTitle)
                    }
                    editingSessionId = nil
                },
                secondaryButton: .cancel {
                    editingSessionId = nil
                }
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ChatListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatListView()
                .environmentObject(ChatHistoryManager(settingsManager: SettingsManager()))
        }
    }
}
