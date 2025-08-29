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
    let prompt: String
    let placeholder: String
    
    static let homeHealthQuestions = [
        Question(
            number: 1,
            prompt: "What is the patient's name?",
            placeholder: "Enter patient's full name"
        ),
        Question(
            number: 2,
            prompt: "How is the patient's mental status and alertness?",
            placeholder: "Describe orientation, alertness, and cognitive status"
        ),
        Question(
            number: 3,
            prompt: "How is the patient's mobility and safety?",
            placeholder: "Describe ambulation, transfers, fall risk, and safety concerns"
        ),
        Question(
            number: 4,
            prompt: "What is the medication compliance status?",
            placeholder: "Describe medication adherence and any issues"
        ),
        Question(
            number: 5,
            prompt: "Were any treatments or wound care performed?",
            placeholder: "Describe treatments, wound care, or procedures performed"
        ),
        Question(
            number: 6,
            prompt: "What patient education was provided?",
            placeholder: "Describe teaching provided and patient understanding"
        ),
        Question(
            number: 7,
            prompt: "What is the plan for the next visit?",
            placeholder: "Describe follow-up plans and next visit objectives"
        )
    ]
}