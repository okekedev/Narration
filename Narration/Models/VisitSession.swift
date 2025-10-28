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
    @Published var questions: [Question] = []
    @Published var responses: [String] = []
    @Published var currentQuestionIndex = 0
    @Published var generatedNarrative = ""
    @Published var isGenerating = false

    private var templateManager = TemplateManager.shared

    init() {
        loadQuestionsFromTemplate()
    }

    func loadQuestionsFromTemplate() {
        if let template = templateManager.selectedTemplate {
            questions = template.questions
            // Resize responses array to match question count
            if responses.count != questions.count {
                responses = Array(repeating: "", count: questions.count)
            }
        } else {
            // Fallback to default questions
            questions = Question.homeHealthQuestions
            responses = Array(repeating: "", count: 7)
        }
    }
    
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
        loadQuestionsFromTemplate() // Reload questions from current template
        responses = Array(repeating: "", count: questions.count)
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
