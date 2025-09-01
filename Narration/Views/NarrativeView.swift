//
//  NarrativeView.swift
//  Narration
//
//  Complete clinical documentation workflow: Questions → Narrative
//

import SwiftUI

struct NarrativeView: View {
    @ObservedObject var session: VisitSession
    @StateObject private var narrativeService = NarrativeGenerationService()
    @EnvironmentObject var speechService: SpeechRecognitionService
    @Environment(\.dismiss) private var dismiss
    @State private var showingCopiedAlert = false
    @State private var autoCopyTimeRemaining = 30
    @State private var autoCopyTimer: Timer?
    @State private var isInReviewPeriod = true
    @State private var editableNarrative = ""
    @State private var isEditing = false
    @State private var showingNarrativeView = false
    @State private var showingQuestionsEdit = false
    
    var body: some View {
        NavigationStack {
            if !showingNarrativeView {
                // Questions workflow
                questionWorkflowView
            } else {
                // Final narrative view
                finalNarrativeView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Question Workflow View
    private var questionWorkflowView: some View {
        VStack(spacing: 0) {
            // Header with progress and timer
            VStack(spacing: 16) {
                // Progress bar
                ProgressView(value: max(0, min(1, session.progress)))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(height: 4)
                
                HStack {
                    Text("Question \(session.currentQuestion.number)")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(session.currentQuestion.number) of \(session.questions.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color(.systemBackground))
            
            ScrollView {
                VStack(spacing: 24) {
                    // Question card
                    VStack(alignment: .leading, spacing: 20) {
                        Text(session.currentQuestion.prompt)
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        // Text input area
                        VStack(alignment: .leading, spacing: 12) {
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: binding(for: session.currentQuestionIndex))
                                    .frame(minHeight: currentTextIsEmpty ? 50 : max(50, textHeight))
                                    .padding(16)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(speechService.isRecording ? Color.blue : Color(.systemGray4), lineWidth: speechService.isRecording ? 2 : 1)
                                    )
                                    .animation(.easeInOut(duration: 0.3), value: textHeight)
                                    .animation(.easeInOut(duration: 0.2), value: speechService.isRecording)
                                
                                // Placeholder
                                if currentTextIsEmpty {
                                    Text(session.currentQuestion.placeholder)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 20)
                                        .allowsHitTesting(false)
                                }
                            }
                            
                            // Voice transcription overlay
                            if !speechService.recognizedText.isEmpty || !speechService.errorMessage.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "waveform")
                                            .foregroundColor(.blue)
                                        Text("Voice Input")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                        Spacer()
                                    }
                                    
                                    Text(speechService.errorMessage.isEmpty ? speechService.recognizedText : speechService.errorMessage)
                                        .font(.body)
                                        .padding(16)
                                        .background(isNoAudioMessage ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isNoAudioMessage ? Color.orange.opacity(0.3) : Color.blue.opacity(0.3), lineWidth: 1)
                                        )
                                    
                                    if !isNoAudioMessage {
                                        Button(action: insertVoiceText) {
                                            HStack {
                                                Image(systemName: "arrow.down.circle.fill")
                                                Text("Insert Text")
                                            }
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 12)
                                            .background(Color.blue)
                                            .cornerRadius(8)
                                        }
                                    } else {
                                        HStack {
                                            Image(systemName: "info.circle")
                                                .foregroundColor(.orange)
                                            Text("Try speaking louder or closer to the microphone")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.top, 4)
                                    }
                                }
                                .padding(.top, 8)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    .padding(24)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                
                    // Voice control button
                    VStack(spacing: 16) {
                        Button(action: toggleRecording) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(speechService.isRecording ? Color.red : Color.blue)
                                        .frame(width: 64, height: 64)
                                    
                                    if speechService.isProcessing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: speechService.isRecording ? "stop.fill" : "mic.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                Text(speechService.isProcessing ? "Processing" :
                                     speechService.isRecording ? "Recording" : "Voice Input")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(speechService.isRecording ? .red : .blue)
                            }
                        }
                        .scaleEffect(speechService.isRecording ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: speechService.isRecording)
                        
                        // Status indicator
                        if !speechService.whisperKitReady {
                            Text("Loading AI...")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            
            // Navigation buttons
            HStack(spacing: 16) {
                Button(action: {
                    speechService.clearText()
                    session.moveToPrevious()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(session.isFirstQuestion ? .secondary : .blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(session.isFirstQuestion ? Color(.systemGray5) : Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .disabled(session.isFirstQuestion)
                
                Spacer()
                
                if session.isLastQuestion {
                    Button(action: {
                        speechService.clearText()
                        showingNarrativeView = true
                    }) {
                        HStack {
                            Text("Generate Narrative")
                            Image(systemName: "wand.and.stars")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(hasAnyResponses ? Color.blue : Color(.systemGray4))
                        .cornerRadius(8)
                    }
                    .disabled(!hasAnyResponses)
                } else {
                    Button(action: {
                        speechService.clearText()
                        session.moveToNext()
                    }) {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color(.systemBackground))
        }
        .navigationTitle("Clinical Documentation")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button("Questions") {
                        showingQuestionsEdit = true
                    }
                    .foregroundColor(.blue)
                    
                    Button("New Session") {
                        session.startNewSession()
                        showingNarrativeView = false
                        speechService.clearText()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingQuestionsEdit) {
            QuestionsEditView(session: session)
        }
    }
    
    // MARK: - Final Narrative View
    private var finalNarrativeView: some View {
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
                        HStack {
                            Text("Generated Clinical Narrative")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            // Edit toggle button
                            Button(action: { isEditing.toggle() }) {
                                HStack {
                                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle")
                                    Text(isEditing ? "Done" : "Edit")
                                }
                                .foregroundColor(.blue)
                            }
                        }
                        
                        // Editable narrative text
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $editableNarrative)
                                .font(.body)
                                .lineSpacing(4)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .disabled(!isEditing)
                                .opacity(isEditing ? 1.0 : 0.9)
                                .frame(minHeight: 200)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isEditing ? Color.blue : Color.clear, lineWidth: 2)
                                )
                            
                            // Placeholder when empty
                            if editableNarrative.isEmpty && !isEditing {
                                Text("No narrative generated yet")
                                    .foregroundColor(.secondary)
                                    .padding(16)
                                    .allowsHitTesting(false)
                            }
                        }
                        
                        // Voice input section (only show when editing)
                        if isEditing {
                            VStack(spacing: 12) {
                                // Voice transcription overlay
                                if !speechService.recognizedText.isEmpty || !speechService.errorMessage.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "waveform")
                                                .foregroundColor(.blue)
                                            Text("Voice Input")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.blue)
                                            Spacer()
                                        }
                                        
                                        Text(speechService.errorMessage.isEmpty ? speechService.recognizedText : speechService.errorMessage)
                                            .font(.body)
                                            .padding(16)
                                            .background(speechService.errorMessage.isEmpty ? Color.blue.opacity(0.1) : Color.orange.opacity(0.1))
                                            .cornerRadius(12)
                                        
                                        if speechService.errorMessage.isEmpty && !speechService.recognizedText.isEmpty {
                                            Button(action: insertVoiceTextInNarrative) {
                                                HStack {
                                                    Image(systemName: "arrow.down.circle.fill")
                                                    Text("Insert Text")
                                                }
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 12)
                                                .background(Color.blue)
                                                .cornerRadius(8)
                                            }
                                        }
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                                
                                // Voice control button
                                Button(action: toggleRecording) {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            // Pulsing background circle when recording
                                            if speechService.isRecording {
                                                Circle()
                                                    .fill(Color.red.opacity(0.3))
                                                    .frame(width: 80, height: 80)
                                                    .scaleEffect(speechService.isRecording ? 1.2 : 1.0)
                                                    .animation(
                                                        .easeInOut(duration: 0.6)
                                                        .repeatForever(autoreverses: true),
                                                        value: speechService.isRecording
                                                    )
                                            }
                                            
                                            Circle()
                                                .fill(speechService.isRecording ? Color.red : Color.blue)
                                                .frame(width: 64, height: 64)
                                            
                                            if speechService.isProcessing {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            } else {
                                                Image(systemName: speechService.isRecording ? "stop.fill" : "mic.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        
                                        Text(speechService.isProcessing ? "Processing" :
                                             speechService.isRecording ? "Recording" : "Voice Input")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(speechService.isRecording ? .red : .blue)
                                    }
                                }
                                .scaleEffect(speechService.isRecording ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: speechService.isRecording)
                            }
                        }
                        
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
                            
                            // Auto-copy timer (only when active)
                            if !isInReviewPeriod {
                                VStack(spacing: 8) {
                                    HStack {
                                        Image(systemName: "clock")
                                            .foregroundColor(.orange)
                                        Text("New session starts in \(autoCopyTimeRemaining) seconds")
                                            .font(.subheadline)
                                            .foregroundColor(.orange)
                                    }
                                    
                                    ProgressView(value: max(0, min(30, Double(30 - autoCopyTimeRemaining))), total: 30)
                                        .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                                        .scaleEffect(y: 2)
                                    
                                    Button("Cancel Timer") {
                                        stopAutoCopyTimer()
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            } else {
                                Button("Start New Session Timer") {
                                    startAutoCopyTimer()
                                }
                                .font(.subheadline)
                                .foregroundColor(.green)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                }
                .simultaneousGesture(
                    TapGesture().onEnded { _ in
                        // Force dismiss keyboard
                        UIApplication.shared.windows.first?.endEditing(true)
                        
                        // Auto-exit edit mode like clicking "Done"
                        if isEditing {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isEditing = false
                            }
                        }
                    }
                )
            }
        }
        .navigationTitle("Clinical Narrative")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back to Questions") {
                    showingNarrativeView = false
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("New Session") {
                    session.startNewSession()
                    showingNarrativeView = false
                    speechService.clearText()
                }
                .foregroundColor(.blue)
            }
        }
        .task {
            await generateNarrative()
        }
        .onAppear {
            // Initialize editable narrative with generated text
            editableNarrative = session.generatedNarrative
        }
        .onChange(of: session.generatedNarrative) { newValue in
            editableNarrative = newValue
        }
        .onDisappear {
            stopAutoCopyTimer()
        }
        .alert("Copied!", isPresented: $showingCopiedAlert) {
            Button("OK") { }
        } message: {
            Text("Narrative has been copied to clipboard. All session data will be cleared for privacy.")
        }
    }
    
    // MARK: - Helper Functions
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
    
    private func startAutoCopyTimer() {
        isInReviewPeriod = false
        autoCopyTimeRemaining = 30
        autoCopyTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if self.autoCopyTimeRemaining > 0 {
                self.autoCopyTimeRemaining = max(0, self.autoCopyTimeRemaining - 1)
            } else {
                self.copyToClipboard()
                self.stopAutoCopyTimer()
            }
        }
    }
    
    private func stopAutoCopyTimer() {
        autoCopyTimer?.invalidate()
        autoCopyTimer = nil
        isInReviewPeriod = true
    }
    
    private func copyToClipboard() {
        stopAutoCopyTimer()
        // Copy the edited narrative, not the original
        UIPasteboard.general.string = editableNarrative
        showingCopiedAlert = true
        
        // Clear session data after copying for privacy
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            session.clearSession()
            speechService.clearText()
        }
    }
    
    private func toggleRecording() {
        if speechService.isRecording {
            speechService.stopRecording()
        } else {
            Task {
                do {
                    try await speechService.startRecording()
                } catch {
                    print("Speech recognition failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func insertVoiceText() {
        withAnimation(.easeInOut(duration: 0.3)) {
            // Append voice text to existing response instead of replacing
            let currentText = session.responses[session.currentQuestionIndex]
            let newText = speechService.recognizedText
            
            if currentText.isEmpty {
                // If empty, just set the new text
                session.responses[session.currentQuestionIndex] = newText
            } else {
                // If there's existing text, append with a space or period
                let separator = currentText.hasSuffix(".") || currentText.hasSuffix("?") || currentText.hasSuffix("!") 
                    ? " " : ". "
                session.responses[session.currentQuestionIndex] = currentText + separator + newText
            }
            
            speechService.clearText()
        }
    }
    
    private func insertVoiceTextInNarrative() {
        withAnimation(.easeInOut(duration: 0.3)) {
            // Append voice text to narrative
            let newText = speechService.recognizedText
            
            if editableNarrative.isEmpty {
                editableNarrative = newText
            } else {
                // Add appropriate spacing/punctuation
                let separator = editableNarrative.hasSuffix(".") || 
                               editableNarrative.hasSuffix("?") || 
                               editableNarrative.hasSuffix("!") 
                    ? " " : ". "
                editableNarrative = editableNarrative + separator + newText
            }
            
            speechService.clearText()
        }
    }
    
    // MARK: - Computed Properties
    private var currentTextIsEmpty: Bool {
        session.responses[session.currentQuestionIndex].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var textHeight: CGFloat {
        let text = session.responses[session.currentQuestionIndex]
        let lines = max(1, text.components(separatedBy: .newlines).count)
        return CGFloat(lines * 20 + 20) // Approximate line height + padding
    }
    
    private var hasAnyResponses: Bool {
        session.responses.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    private var isNoAudioMessage: Bool {
        return !speechService.errorMessage.isEmpty
    }
    
    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { session.responses[index] },
            set: { newValue in
                session.responses[index] = newValue
            }
        )
    }
}