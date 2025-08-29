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
    @StateObject private var privacyManager = PrivacyManager.shared
    @StateObject private var speechService = SpeechRecognitionService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(privacyManager)
                .environmentObject(speechService)
                .onAppear {
                    privacyManager.scheduleAutoClear()
                    privacyManager.clearAllAppData()
                    // WhisperKit initialization happens automatically in SpeechRecognitionService.shared
                }
        }
    }
}
