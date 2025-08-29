//
//  ContentView.swift
//  Narration
//
//  Home Health Narrative Generator - Main Interface
//

import SwiftUI

struct ContentView: View {
    @State private var showingOnboarding = true
    
    var body: some View {
        if showingOnboarding {
            OnboardingView {
                showingOnboarding = false
            }
        } else {
            QuestionAnswerView()
        }
    }
}

#Preview {
    ContentView()
}
