//
//  PrivacyManager.swift
//  Narration
//
//  Privacy and compliance manager for HIPAA-compliant operation
//

import Foundation
import SwiftUI

@MainActor
class PrivacyManager: ObservableObject {
    static let shared = PrivacyManager()
    
    @Published var isDataCleared = true
    @Published var lastClearTime: Date?
    
    private init() {}
    
    func clearAllAppData() {
        // Clear any cached data
        clearTemporaryData()
        clearUserDefaults()
        clearClipboardIfNeeded()
        
        isDataCleared = true
        lastClearTime = Date()
    }
    
    private func clearTemporaryData() {
        // Clear any temporary files or cached data
        let tempDirectory = NSTemporaryDirectory()
        let fileManager = FileManager.default
        
        do {
            let tempFiles = try fileManager.contentsOfDirectory(atPath: tempDirectory)
            for file in tempFiles {
                let filePath = tempDirectory + file
                try fileManager.removeItem(atPath: filePath)
            }
        } catch {
            print("Error clearing temporary files: \(error)")
        }
    }
    
    private func clearUserDefaults() {
        // Clear any UserDefaults data (though we don't store any sensitive data there)
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        
        for key in dictionary.keys {
            if key.hasPrefix("com.homehealth.narrative") {
                defaults.removeObject(forKey: key)
            }
        }
    }
    
    private func clearClipboardIfNeeded() {
        // Note: We don't automatically clear system clipboard as it may contain
        // user data from other apps. The user is informed to manually clear if needed.
    }
    
    func scheduleAutoClear() {
        // Auto-clear sensitive data after app becomes inactive
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.clearAllAppData()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.clearAllAppData()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}