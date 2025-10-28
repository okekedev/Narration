//
//  NarrativeView.swift
//  Narration
//
//  Complete clinical documentation workflow: Questions → Narrative
//

import SwiftUI

struct NarrativeView: View {
    @ObservedObject var session: VisitSession
    @State private var narrativeService = NarrativeGenerationService()
    @State private var speechService = SpeechRecognitionService.shared
    @State private var showingCopiedAlert = false
    @State private var editableNarrative = ""
    @State private var showingNarrativeView = false
    @State private var showingTemplates = false
    @State private var elementsVisible = false

    var body: some View {
        NavigationStack {
            if showingNarrativeView {
                narrativeView
            } else {
                questionsView
            }
        }
        .sheet(isPresented: $showingTemplates) {
            TemplateListView()
        }
        .alert("Copied!", isPresented: $showingCopiedAlert) {
            Button("OK") { }
        } message: {
            Text("No data will be stored on this device after you copy.")
        }
    }
    
    // MARK: - Questions View
    private var questionsView: some View {
        VStack(spacing: 20) {
            headerSection
            questionSection
            Spacer()
            controlsSection
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 0)
        }
        .onTapGesture {
            hideKeyboard()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    showingTemplates = true
                }) {
                    Image(systemName: "line.3.horizontal")
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("New") {
                    newSession()
                }
                .foregroundColor(.blue)
            }
        }
        .onAppear {
            // Delay to ensure view is fully loaded before animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    elementsVisible = true
                }
            }
            
            // Set up direct text insertion callback
            speechService.onTextRecognized = { [session] recognizedText in
                guard !recognizedText.isEmpty else { return }
                
                let currentText = session.responses[session.currentQuestionIndex]
                
                if currentText.isEmpty {
                    session.responses[session.currentQuestionIndex] = recognizedText
                } else {
                    let separator = currentText.last == "." || currentText.last == "?" || currentText.last == "!" ? " " : ". "
                    session.responses[session.currentQuestionIndex] = currentText + separator + recognizedText
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            let progressValue = session.progress.isFinite && !session.progress.isNaN ? session.progress : 0.0
            ProgressView(value: progressValue)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(height: 4)
            
            HStack {
                Text(session.currentQuestion.sectionTitle)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(session.currentQuestion.number) of \(session.questions.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .opacity(elementsVisible ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.6), value: elementsVisible)
    }
    
    private var questionSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(session.currentQuestion.prompt)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(16)
                    .background(Color.blue)
                    .cornerRadius(12)
                
                textInputField
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
            .padding(.horizontal, 24)
        }
        .opacity(elementsVisible ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.6), value: elementsVisible)
    }
    
    private var textInputField: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: currentResponseBinding)
                .frame(minHeight: 80)
                .padding(16)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(speechService.isRecording ? Color.blue : Color(.systemGray4), 
                               lineWidth: speechService.isRecording ? 2 : 1)
                )
                .onAppear {
                    UITextView.appearance().inputAssistantItem.leadingBarButtonGroups = []
                    UITextView.appearance().inputAssistantItem.trailingBarButtonGroups = []
                }
            
            if currentResponse.isEmpty {
                Text(session.currentQuestion.placeholder)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .allowsHitTesting(false)
            }
        }
    }
    
    
    private var controlsSection: some View {
        HStack(spacing: 30) {
            // Previous button
            Button {
                speechService.clearText()
                session.moveToPrevious()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(session.isFirstQuestion ? .secondary : .blue)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(session.isFirstQuestion ? Color(.systemGray6) : Color.blue.opacity(0.1))
                    )
            }
            .disabled(session.isFirstQuestion)
            
            Spacer()
            
            // Microphone button
            microphoneButton
            
            Spacer()
            
            // Next/Generate button
            Button {
                speechService.clearText()
                if session.isLastQuestion {
                    print("Going to narrative view - last question reached")
                    showingNarrativeView = true
                } else {
                    print("Moving to next question: \(session.currentQuestionIndex + 1)")
                    session.moveToNext()
                }
            } label: {
                Image(systemName: session.isLastQuestion ? "sparkles" : "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle().fill(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.85)], 
                                startPoint: .top, 
                                endPoint: .bottom
                            )
                        )
                    )
                    .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .disabled(session.isLastQuestion && !hasAnyResponses)
        }
        .padding(.horizontal, 24)
        .opacity(elementsVisible ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.6), value: elementsVisible)
    }
    
    private var microphoneButton: some View {
        Button {
            toggleRecording()
        } label: {
            ZStack {
                // Pulsing background when recording
                if speechService.isRecording {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .scaleEffect(1.2)
                        .opacity(0.5)
                        .animation(
                            .easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true),
                            value: speechService.isRecording
                        )
                }
                
                // Main button
                Circle()
                    .fill(micButtonGradient)
                    .frame(width: 65, height: 65)
                    .shadow(color: micShadowColor, radius: 8, x: 0, y: 4)
                
                // Content
                if speechService.isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.3)
                } else {
                    Image(systemName: micIcon)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .scaleEffect(speechService.isRecording ? 1.08 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: speechService.isRecording)
    }
    
    // MARK: - Narrative View
    private var narrativeView: some View {
        VStack(spacing: 20) {
            if session.isGenerating {
                generateProgressView
            } else {
                narrativeContentView
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back to Questions") {
                    showingNarrativeView = false
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("New") {
                    continueToNewSession()
                }
                .foregroundColor(.blue)
            }
        }
        .task {
            await generateNarrative()
        }
        .onAppear {
            editableNarrative = session.generatedNarrative
        }
        .onChange(of: session.generatedNarrative) { _, newValue in
            if editableNarrative.isEmpty || editableNarrative == "Error generating narrative. Please try again." {
                editableNarrative = newValue
            }
        }
    }
    
    private var generateProgressView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Generating clinical narrative...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var narrativeContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text("Narrative")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                // Narrative text editor - always editable
                narrativeEditor
                
                // Copy button
                Button("Copy to Clipboard") {
                    copyToClipboard()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }
    
    private var narrativeEditor: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $editableNarrative)
                .font(.body)
                .lineSpacing(4)
                .padding(16)
                .cornerRadius(12)
                .frame(minHeight: 250)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 2)
                )
            
            if editableNarrative.isEmpty {
                Text("Your narrative will appear here...")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .allowsHitTesting(false)
            }
        }
    }
    
    
    // MARK: - Computed Properties
    private var currentResponse: String {
        session.responses[session.currentQuestionIndex]
    }
    
    private var currentResponseBinding: Binding<String> {
        Binding(
            get: { session.responses[session.currentQuestionIndex] },
            set: { session.responses[session.currentQuestionIndex] = $0 }
        )
    }
    
    // Removed computed properties - using inline logic to avoid property wrapper issues
    
    private var micButtonGradient: LinearGradient {
        let colors = speechService.isRecording ? 
            [Color.green, Color.green.opacity(0.85)] :
            [Color.blue, Color.blue.opacity(0.85)]
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }
    
    private var micShadowColor: Color {
        speechService.isRecording ? Color.green.opacity(0.4) : Color.blue.opacity(0.4)
    }
    
    private var micIcon: String {
        speechService.isRecording ? "pause.fill" : "mic.fill"
    }
    
    private var hasAnyResponses: Bool {
        session.responses.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    // MARK: - Actions
    private func newSession() {
        session.startNewSession()
        showingNarrativeView = false
        speechService.clearText()
    }
    
    private func continueToNewSession() {
        session.startNewSession() 
        showingNarrativeView = false // Go back to questions for new session
        speechService.clearText()
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
    
    // Voice text insertion now handled by direct callback
    
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
    
    private func copyToClipboard() {
        UIPasteboard.general.string = editableNarrative
        showingCopiedAlert = true
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            session.clearSession()
            speechService.clearText()
            continueToNewSession() // Auto-start new session after copy
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
