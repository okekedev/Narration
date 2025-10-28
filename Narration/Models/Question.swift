//
//  Question.swift
//  Narration
//
//  Home Health Visit Question Model
//

import Foundation

struct Question: Identifiable, Equatable, Codable, Hashable {
    var id: UUID
    var number: Int
    var prompt: String
    var sectionTitle: String
    var placeholder: String = ""

    init(id: UUID = UUID(), number: Int, prompt: String, sectionTitle: String) {
        self.id = id
        self.number = number
        self.prompt = prompt
        self.sectionTitle = sectionTitle
    }
    
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