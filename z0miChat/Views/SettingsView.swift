//
//  SettingsView.swift
//  z0miChat
//
//  Created by Aleksey Cherkasskiy on 15.03.2025.
//


import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var modelManager: ModelManager
    
    @State private var liteLLMURL = ""
    @State private var liteLLMKey = ""
    @State private var openAIKey = ""
    @State private var claudeKey = ""
    @State private var deepSeekKey = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section(header: Text("LiteLLM Server")) {
                TextField("Server URL", text: $liteLLMURL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    
                SecureField("API Key", text: $liteLLMKey)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            Section(header: Text("OpenAI")) {
                SecureField("API Key", text: $openAIKey)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            Section(header: Text("Anthropic Claude")) {
                SecureField("API Key", text: $claudeKey)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            Section(header: Text("DeepSeek")) {
                SecureField("API Key", text: $deepSeekKey)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            Section {
                Button("Save Settings") {
                    saveSettings()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.blue)
                
                Button("Test Connection") {
                    testConnection()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.green)
            }
        }
        .onAppear {
            // Load existing settings
            liteLLMURL = settingsManager.liteLLMURL
            liteLLMKey = settingsManager.liteLLMKey
            openAIKey = settingsManager.openAIKey
            claudeKey = settingsManager.claudeKey
            deepSeekKey = settingsManager.deepSeekKey
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Connection Test"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func saveSettings() {
        settingsManager.liteLLMURL = liteLLMURL.trimmingCharacters(in: .whitespacesAndNewlines)
        settingsManager.liteLLMKey = liteLLMKey.trimmingCharacters(in: .whitespacesAndNewlines)
        settingsManager.openAIKey = openAIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        settingsManager.claudeKey = claudeKey.trimmingCharacters(in: .whitespacesAndNewlines)
        settingsManager.deepSeekKey = deepSeekKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Save to user defaults
        settingsManager.saveSettings()
        
        // Refresh models
        Task {
            await modelManager.fetchAvailableModels()
        }
    }
    
    private func testConnection() {
        // First, save current settings so test uses the latest values
        saveSettings()
        
        Task {
            do {
                let success = try await modelManager.testConnection(
                    liteLLMURL: liteLLMURL.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                
                await MainActor.run {
                    if success {
                        alertMessage = "Connection successful!"
                    } else {
                        alertMessage = "Connection failed. Please check the server URL and API keys."
                    }
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Error: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(ModelManager(settingsManager: SettingsManager()))
            .environmentObject(SettingsManager())
    }
}
