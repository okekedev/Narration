//
//  VisitSession.swift
//  Narration
//
//  Home Health Visit Session Model
//

import Foundation
import SwiftUI

@MainActor
class VisitSession: ObservableObject {
    @Published var questions = Question.homeHealthQuestions
    @Published var responses: [String] = Array(repeating: "", count: 7)
    @Published var currentQuestionIndex = 0
    @Published var generatedNarrative = ""
    @Published var isGenerating = false
    @Published var sessionTimeRemaining = 600 // 10 minutes in seconds
    @Published var isSessionActive = false
    
    private var sessionTimer: Timer?
    
    var currentQuestion: Question {
        questions[currentQuestionIndex]
    }
    
    var isFirstQuestion: Bool {
        currentQuestionIndex == 0
    }
    
    var isLastQuestion: Bool {
        currentQuestionIndex == questions.count - 1
    }
    
    var progress: Double {
        let total = questions.count
        guard total > 0 else { return 0 }
        let current = max(0, min(total - 1, currentQuestionIndex))
        return Double(current + 1) / Double(total)
    }
    
    func moveToNext() {
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
        }
    }
    
    func moveToPrevious() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        }
    }
    
    func startNewSession() {
        clearSession()
        startSessionTimer()
    }
    
    func clearSession() {
        responses = Array(repeating: "", count: 7)
        currentQuestionIndex = 0
        generatedNarrative = ""
        isGenerating = false
        stopSessionTimer()
    }
    
    private func startSessionTimer() {
        sessionTimeRemaining = 600
        isSessionActive = true
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.sessionTimeRemaining > 0 {
                self.sessionTimeRemaining = max(0, self.sessionTimeRemaining - 1)
            } else {
                self.stopSessionTimer()
            }
        }
    }
    
    private func stopSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        isSessionActive = false
    }
    
    func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    deinit {
        Task { @MainActor in
            stopSessionTimer()
        }
    }
    
    func allQuestionsAnswered() -> Bool {
        !responses.contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
    }
}
