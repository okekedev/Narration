//
//  QuestionAnswerView.swift
//  Narration
//
//  Q&A interface with voice input for home health visits
//

import SwiftUI

struct QuestionAnswerView: View {
    @StateObject private var session = VisitSession()
    @EnvironmentObject var speechService: SpeechRecognitionService
    @State private var showingNarrative = false
    @State private var showingQuestionReference = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Clean header with progress
                VStack(spacing: 16) {
                    // Minimal progress bar
                    ProgressView(value: max(0, min(1, session.progress)))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(height: 4)
                    
                    HStack {
                        Text("Question \(session.currentQuestion.number)")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(session.currentQuestion.number) of \(Question.homeHealthQuestions.count)")
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
                            
                            // Dynamic text input area
                            VStack(alignment: .leading, spacing: 12) {
                                ZStack(alignment: .topLeading) {
                                    // Responsive text editor
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
                                if !speechService.recognizedText.isEmpty {
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
                                        
                                        Text(speechService.recognizedText)
                                            .font(.body)
                                            .padding(16)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                            )
                                        
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
                    
                        // Floating voice control
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
                            .disabled(!speechService.isAuthorized)
                            .scaleEffect(speechService.isRecording ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: speechService.isRecording)
                            
                            // Status indicator
                            if !speechService.whisperKitReady && speechService.isAuthorized {
                                Text("Loading AI...")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                // Clean navigation
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
                            showingNarrative = true
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
            .padding()
            .navigationTitle("Home Health Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingQuestionReference = true
                    }) {
                        HStack {
                            Image(systemName: "list.bullet.circle")
                            Text("Questions")
                        }
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear All") {
                        session.clearSession()
                        speechService.clearText()
                    }
                    .foregroundColor(.red)
                }
            }
            .fullScreenCover(isPresented: $showingNarrative) {
                NarrativeView(session: session)
            }
            .sheet(isPresented: $showingQuestionReference) {
                QuestionReferenceView()
            }
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
    
    // MARK: - Functions
    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { session.responses[index] },
            set: { newValue in
                session.responses[index] = newValue
            }
        )
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
            session.responses[session.currentQuestionIndex] = speechService.recognizedText
            speechService.clearText()
        }
    }
}