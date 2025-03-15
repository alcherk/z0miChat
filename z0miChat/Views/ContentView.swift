//
//  ContentView.swift
//  z0miChat
//
//  Created by Aleksey Cherkasskiy on 15.03.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var isSettingsPresented = false
    @EnvironmentObject private var modelManager: ModelManager
    
    var body: some View {
        NavigationView {
            ChatView()
                .navigationTitle("AI Chat")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isSettingsPresented = true
                        }) {
                            Image(systemName: "gear")
                        }
                    }
                }
        }
        .sheet(isPresented: $isSettingsPresented) {
            NavigationView {
                SettingsView()
                    .navigationTitle("Settings")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                isSettingsPresented = false
                            }
                        }
                    }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ModelManager(settingsManager: SettingsManager()))
            .environmentObject(SettingsManager())
            .environmentObject(ChatHistoryManager(settingsManager: SettingsManager()))
    }
}
