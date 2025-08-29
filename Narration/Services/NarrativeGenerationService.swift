//
//  NarrativeGenerationService.swift
//  Narration
//
//  Simple narrative formatting service
//

import Foundation

@MainActor
class NarrativeGenerationService: ObservableObject {
    
    func generateNarrative(responses: [String]) async throws -> String {
        guard responses.count == 7 else {
            throw NarrativeError.invalidResponseCount
        }
        
        // Simulate brief processing time
        try await Task.sleep(for: .seconds(1))
        
        return formatNarrative(from: responses)
    }
    
    private func formatNarrative(from responses: [String]) -> String {
        let patientName = responses[0].isEmpty ? "[Patient Name]" : responses[0]
        
        var narrative = "Made home visit to see \(patientName) today. "
        
        // Mental/cognitive status
        if !responses[1].isEmpty {
            narrative += "I found patient to be \(responses[1]). "
        } else {
            narrative += "Patient appeared alert and oriented during my assessment. "
        }
        
        // Mobility and safety
        if !responses[2].isEmpty {
            narrative += "Regarding mobility and safety, I observed \(responses[2]). "
        } else {
            narrative += "Patient was ambulatory without difficulty noted. "
        }
        
        // Medication compliance
        if !responses[3].isEmpty {
            narrative += "Patient states \(responses[3]) regarding medications. "
        } else {
            narrative += "Patient reports taking medications as prescribed. "
        }
        
        // Treatments/care provided
        if !responses[4].isEmpty {
            narrative += "I provided \(responses[4]) during today's visit. "
        }
        
        // Patient education
        if !responses[5].isEmpty {
            narrative += "I instructed patient on \(responses[5]). Patient verbalized understanding. "
        }
        
        // Next visit plan
        if !responses[6].isEmpty {
            narrative += "Plan for next visit is to \(responses[6]). "
        } else {
            narrative += "Will continue with current plan of care on next visit. "
        }
        
        narrative += "Patient's home environment remains safe. Will continue skilled nursing visits per physician orders."
        
        return narrative
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