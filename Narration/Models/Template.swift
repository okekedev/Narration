//
//  Template.swift
//  Narration
//
//  Created by Claude on 10/28/25.
//

import Foundation

struct Template: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var questions: [Question]
    var dateCreated: Date
    var dateModified: Date
    var isDefault: Bool

    init(id: UUID = UUID(), name: String, questions: [Question], dateCreated: Date = Date(), dateModified: Date = Date(), isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.questions = questions
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.isDefault = isDefault
    }

    // Create default template with existing home health questions
    static var defaultTemplate: Template {
        Template(
            name: "Home Health Visit",
            questions: Question.homeHealthQuestions,
            isDefault: true
        )
    }

    // Encode to JSON for sharing
    func toJSON() -> Data? {
        try? JSONEncoder().encode(self)
    }

    // Decode from JSON
    static func fromJSON(_ data: Data) -> Template? {
        try? JSONDecoder().decode(Template.self, from: data)
    }

    // Create shareable string (base64 encoded JSON)
    func toShareableString() -> String? {
        guard let jsonData = toJSON() else { return nil }
        return jsonData.base64EncodedString()
    }

    // Create template from shareable string
    static func fromShareableString(_ string: String) -> Template? {
        guard let data = Data(base64Encoded: string) else { return nil }
        return fromJSON(data)
    }
}
