//
//  KeychainManager.swift
//  z0miChat
//
//  Created by Aleksey Cherkasskiy on 15.03.2025.
//


import Foundation
import Security

class KeychainManager {
    static func save(key: String, data: String) {
        guard let data = data.data(using: .utf8) else { return }
        
        // Create query
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ] as [String: Any]
        
        // Delete any existing items
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func load(key: String) -> String? {
        // Create query
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ] as [String: Any]
        
        var dataTypeRef: AnyObject?
        
        // Search for the keychain item
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == noErr {
            if let data = dataTypeRef as? Data,
               let string = String(data: data, encoding: .utf8) {
                return string
            }
        }
        
        return nil
    }
}