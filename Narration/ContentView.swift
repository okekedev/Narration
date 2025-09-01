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
    @StateObject private var session = VisitSession()
    @EnvironmentObject var speechService: SpeechRecognitionService
    
    var body: some View {
        ZStack {
            if isShowingLaunchScreen {
                LaunchScreenView(isLoading: $isShowingLaunchScreen)
                    .transition(.opacity)
            } else {
                NarrativeView(session: session)
                    .transition(.opacity)
                    .onAppear {
                        // Start 10-minute session timer automatically when app loads
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
        // This silently initializes the audio system
        do {
            // Start and immediately stop recording to initialize audio components
            try await speechService.startRecording()
            
            // Wait briefly
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Stop recording
            speechService.stopRecording()
            
            // Clear any text that might have been generated
            speechService.clearText()
            
            print("Audio system pre-initialized")
        } catch {
            print("Pre-initialization skipped: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
}
