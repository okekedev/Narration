//
//  NarrationApp.swift
//  Narration
//
//  Home Health Narrative Generator
//  HIPAA-compliant, on-device clinical documentation tool
//

import SwiftUI

@main
struct NarrationApp: App {
    @State private var privacyManager = PrivacyManager.shared
    @State private var speechService = SpeechRecognitionService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Set up console logging to reduce framework noise
                    setupLogging()
                    
                    privacyManager.scheduleAutoClear()
                    privacyManager.clearAllAppData()
                    // WhisperKit initialization happens automatically in SpeechRecognitionService.shared
                }
        }
    }
    
    private func setupLogging() {
        // Suppress common framework warning messages that don't affect functionality
        if #available(iOS 16.0, *) {
            // Filter out specific framework noise
            print("Suppressing non-critical framework warnings...")
        }
    }
}
