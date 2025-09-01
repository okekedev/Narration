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
    let placeholder: String = ""
    
    static var homeHealthQuestions = [
        Question(
            number: 1,
            prompt: "Who did you visit and what was their condition?"
        ),
        Question(
            number: 2,
            prompt: "What did you observe during your assessment?"
        ),
        Question(
            number: 3,
            prompt: "How was the patient's mobility and daily functioning?"
        ),
        Question(
            number: 4,
            prompt: "What care or treatments did you provide?"
        ),
        Question(
            number: 5,
            prompt: "How did the patient respond to your care?"
        ),
        Question(
            number: 6,
            prompt: "What education or teaching did you provide?"
        ),
        Question(
            number: 7,
            prompt: "What are the next steps and follow-up plans?"
        )
    ]
}