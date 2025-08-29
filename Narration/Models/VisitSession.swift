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
    @Published var responses: [String] = Array(repeating: "", count: 7)
    @Published var currentQuestionIndex = 0
    @Published var generatedNarrative = ""
    @Published var isGenerating = false
    
    var currentQuestion: Question {
        Question.homeHealthQuestions[currentQuestionIndex]
    }
    
    var isFirstQuestion: Bool {
        currentQuestionIndex == 0
    }
    
    var isLastQuestion: Bool {
        currentQuestionIndex == Question.homeHealthQuestions.count - 1
    }
    
    var progress: Double {
        let total = Question.homeHealthQuestions.count
        guard total > 0 else { return 0 }
        let current = max(0, min(total - 1, currentQuestionIndex))
        return Double(current + 1) / Double(total)
    }
    
    func moveToNext() {
        if currentQuestionIndex < Question.homeHealthQuestions.count - 1 {
            currentQuestionIndex += 1
        }
    }
    
    func moveToPrevious() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        }
    }
    
    func clearSession() {
        responses = Array(repeating: "", count: 7)
        currentQuestionIndex = 0
        generatedNarrative = ""
        isGenerating = false
    }
    
    func allQuestionsAnswered() -> Bool {
        !responses.contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
    }
}