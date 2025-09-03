//
//  ContentView.swift
//  Narration
//
//  Home Health Narrative Generator - Main Interface
//

import SwiftUI

struct ContentView: View {
    @State private var isShowingLaunchScreen = true
    @State private var hasPreInitialized = false
    @State private var session = VisitSession()
    @State private var speechService = SpeechRecognitionService.shared
    
    var body: some View {
        ZStack {
            if isShowingLaunchScreen {
                LaunchScreenView(isLoading: $isShowingLaunchScreen)
                    .transition(.opacity)
            } else {
                NarrativeView(session: session)
                    .transition(.opacity)
                    .onAppear {
                        // Initialize new session when app loads
                        session.startNewSession()
                    }
            }
            
            // Hidden view to pre-initialize components
            if !hasPreInitialized {
                Color.clear
                    .frame(width: 0, height: 0)
                    .onAppear {
                        preInitializeComponents()
                    }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: isShowingLaunchScreen)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ResetToLaunchScreen"))) { _ in
            // Reset app to launch screen when background timer expires
            isShowingLaunchScreen = true
            hasPreInitialized = false
            session = VisitSession() // Reset session
            speechService.clearText()
        }
    }
    
    private func preInitializeComponents() {
        // Pre-initialize UI components in background
        Task {
            // Wait a moment for app to stabilize
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Trigger a hidden demo recording to fully initialize audio system
            await triggerHiddenDemoRecording()
            
            hasPreInitialized = true
        }
    }
    
    @MainActor
    private func triggerHiddenDemoRecording() async {
        // Swift 6 - no pre-initialization needed, just mark as ready
        print("App systems ready")
    }
}

#Preview {
    ContentView()
}
