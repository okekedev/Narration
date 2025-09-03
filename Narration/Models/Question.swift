//
//  Question.swift
//  Narration
//
//  Home Health Visit Question Model
//

import Foundation

struct Question: Identifiable, Equatable {
    let id = UUID()
    let number: Int
    var prompt: String
    var sectionTitle: String
    let placeholder: String = ""
    
    static let homeHealthQuestions = [
        Question(
            number: 1,
            prompt: "Who did you visit and what was their condition?",
            sectionTitle: "Patient Information"
        ),
        Question(
            number: 2,
            prompt: "What did you observe during your assessment?",
            sectionTitle: "Assessment Findings"
        ),
        Question(
            number: 3,
            prompt: "How was the patient's mobility and daily functioning?",
            sectionTitle: "Functional Status"
        ),
        Question(
            number: 4,
            prompt: "What care or treatments did you provide?",
            sectionTitle: "Interventions"
        ),
        Question(
            number: 5,
            prompt: "How did the patient respond to your care?",
            sectionTitle: "Patient Response"
        ),
        Question(
            number: 6,
            prompt: "What education or teaching did you provide?",
            sectionTitle: "Patient Education"
        ),
        Question(
            number: 7,
            prompt: "What are the next steps and follow-up plans?",
            sectionTitle: "Follow-up Plan"
        )
    ]
}