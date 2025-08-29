//
//  NarrativeView.swift
//  Narration
//
//  Display and copy generated clinical narrative
//

import SwiftUI

struct NarrativeView: View {
    @ObservedObject var session: VisitSession
    @StateObject private var narrativeService = NarrativeGenerationService()
    @Environment(\.dismiss) private var dismiss
    @State private var showingCopiedAlert = false
    @State private var reviewTimeRemaining = 300 // 5 minutes in seconds
    @State private var autoCopyTimeRemaining = 30
    @State private var timer: Timer?
    @State private var isInReviewPeriod = true
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if session.isGenerating {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Generating clinical narrative...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Generated Clinical Narrative")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(session.generatedNarrative)
                                .font(.body)
                                .lineSpacing(4)
                                .textSelection(.enabled)
                                .padding(16)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            
                            VStack(spacing: 16) {
                                Button(action: copyToClipboard) {
                                    HStack {
                                        Image(systemName: "doc.on.clipboard")
                                        Text("Copy to Clipboard")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                
                                // Review and Auto-copy timer
                                VStack(spacing: 8) {
                                    if isInReviewPeriod {
                                        HStack {
                                            Image(systemName: "doc.text.magnifyingglass")
                                                .foregroundColor(.blue)
                                            Text("Review time: \(formatTime(reviewTimeRemaining))")
                                                .font(.subheadline)
                                                .foregroundColor(.blue)
                                        }
                                        
                                        ProgressView(value: max(0, min(300, Double(300 - reviewTimeRemaining))), total: 300)
                                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                            .scaleEffect(y: 2)
                                        
                                        Button("Done Reviewing - Start Auto-Copy") {
                                            startAutoCopyTimer()
                                        }
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    } else {
                                        HStack {
                                            Image(systemName: "clock")
                                                .foregroundColor(.orange)
                                            Text("Auto-copy in \(autoCopyTimeRemaining) seconds")
                                                .font(.subheadline)
                                                .foregroundColor(.orange)
                                        }
                                        
                                        ProgressView(value: max(0, min(30, Double(30 - autoCopyTimeRemaining))), total: 30)
                                            .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                                            .scaleEffect(y: 2)
                                        
                                        Button("Cancel Auto-Copy") {
                                            stopTimer()
                                        }
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Clinical Narrative")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Visit") {
                        session.clearSession()
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
            .task {
                await generateNarrative()
            }
            .onAppear {
                startReviewTimer()
            }
            .onDisappear {
                stopTimer()
            }
            .alert("Copied!", isPresented: $showingCopiedAlert) {
                Button("OK") { }
            } message: {
                Text("Narrative has been copied to clipboard. All session data will be cleared for privacy.")
            }
        }
    }
    
    private func generateNarrative() async {
        session.isGenerating = true
        
        do {
            let narrative = try await narrativeService.generateNarrative(responses: session.responses)
            session.generatedNarrative = narrative
        } catch {
            session.generatedNarrative = "Error generating narrative. Please try again."
        }
        
        session.isGenerating = false
    }
    
    private func startReviewTimer() {
        isInReviewPeriod = true
        reviewTimeRemaining = 300
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if reviewTimeRemaining > 0 {
                reviewTimeRemaining = max(0, reviewTimeRemaining - 1)
            } else {
                startAutoCopyTimer()
            }
        }
    }
    
    private func startAutoCopyTimer() {
        isInReviewPeriod = false
        autoCopyTimeRemaining = 30
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if autoCopyTimeRemaining > 0 {
                autoCopyTimeRemaining = max(0, autoCopyTimeRemaining - 1)
            } else {
                copyToClipboard()
                stopTimer()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func copyToClipboard() {
        stopTimer()
        UIPasteboard.general.string = session.generatedNarrative
        showingCopiedAlert = true
        
        // Clear session data after copying for privacy
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            session.clearSession()
        }
    }
}