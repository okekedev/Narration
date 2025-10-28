//
//  PrivacyManager.swift
//  Narration
//
//  Privacy and compliance manager for HIPAA-compliant operation
//

import Foundation
import SwiftUI
import UIKit

@MainActor
class PrivacyManager: ObservableObject {
    static let shared = PrivacyManager()
    
    @Published var isDataCleared = true
    @Published var lastClearTime: Date?
    
    private var backgroundTimer: Timer?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private let backgroundTimeout: TimeInterval = 600 // 10 minutes
    
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
        // Handle app entering background - start 10 minute timer
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.startBackgroundTimer()
            }
        }
        
        // Handle app entering foreground - cancel timer
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.cancelBackgroundTimer()
            }
        }
        
        // Handle app termination - immediate clear
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.clearAllAppData()
            }
        }
    }
    
    private func startBackgroundTimer() {
        // Cancel any existing timer
        cancelBackgroundTimer()

        // Request background task to keep app alive briefly
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            // If background time expires, end the task immediately
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                // End background task first to avoid warning
                if self.backgroundTaskID != .invalid {
                    UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
                    self.backgroundTaskID = .invalid
                }
                // Then clear data
                self.clearAllAppData()
            }
        }
        
        // Schedule timer for 10 minutes
        backgroundTimer = Timer.scheduledTimer(withTimeInterval: backgroundTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                print("10 minutes in background - clearing all data for privacy")
                self?.clearDataAndEndBackgroundTask()
            }
        }
        
        print("Started 10-minute background timer")
    }
    
    private func cancelBackgroundTimer() {
        // Cancel timer if app returns to foreground
        backgroundTimer?.invalidate()
        backgroundTimer = nil
        
        // End background task if active
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
        
        print("Cancelled background timer - app returned to foreground")
    }
    
    private func clearDataAndEndBackgroundTask() {
        // Clear all sensitive data
        clearAllAppData()
        
        // Cancel timer
        backgroundTimer?.invalidate()
        backgroundTimer = nil
        
        // End background task
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
        
        // Force clear the session
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            // This will reset the app to launch screen
            NotificationCenter.default.post(name: Notification.Name("ResetToLaunchScreen"), object: nil)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}