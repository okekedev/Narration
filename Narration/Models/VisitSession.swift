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
        guard total > 0 else { return 0.0 }
        let current = max(0, min(total - 1, currentQuestionIndex))
        let progressValue = Double(current + 1) / Double(total)
        
        // Ensure we never return NaN or invalid values
        guard progressValue.isFinite && !progressValue.isNaN else { return 0.0 }
        return min(max(progressValue, 0.0), 1.0) // Clamp between 0 and 1
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
    }
    
    func clearSession() {
        responses = Array(repeating: "", count: 7)
        currentQuestionIndex = 0
        generatedNarrative = ""
        isGenerating = false
    }
    
    
    func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    
    func allQuestionsAnswered() -> Bool {
        !responses.contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
    }
}
