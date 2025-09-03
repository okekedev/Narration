//
//  NarrativeGenerationService.swift
//  Narration
//
//  Simple narrative concatenation service
//

import Foundation

@MainActor
class NarrativeGenerationService: ObservableObject {
    
    func generateNarrative(responses: [String]) async throws -> String {
        // Allow any number of responses, but expect at least one
        guard !responses.isEmpty else {
            return "No responses provided."
        }
        
        // No processing delay needed for simple concatenation
        return concatenateResponses(responses)
    }
    
    private func concatenateResponses(_ responses: [String]) -> String {
        // Filter out empty responses and trim whitespace
        let cleanedResponses = responses
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // If no responses, return empty
        guard !cleanedResponses.isEmpty else {
            return "No responses provided."
        }
        
        // Create natural flowing narrative - ensure each response ends properly
        let formattedResponses = cleanedResponses.map { response in
            let trimmed = response.trimmingCharacters(in: CharacterSet(charactersIn: ".!?"))
            return trimmed.isEmpty ? response : trimmed
        }
        
        // Join responses to create flowing clinical narrative
        return formattedResponses.joined(separator: ". ") + "."
    }
}

enum NarrativeError: Error {
    case invalidResponseCount
    case generationFailed
    
    var localizedDescription: String {
        switch self {
        case .invalidResponseCount:
            return "Invalid number of responses provided"
        case .generationFailed:
            return "Failed to generate narrative"
        }
    }
}