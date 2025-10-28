//
//  TemplateManager.swift
//  Narration
//
//  Created by Claude on 10/28/25.
//

import Foundation
import CoreData
import Combine

@MainActor
@Observable
class TemplateManager {
    static let shared = TemplateManager()

    private let persistenceController = PersistenceController.shared
    private var context: NSManagedObjectContext {
        persistenceController.container.viewContext
    }

    var templates: [Template] = []
    var selectedTemplate: Template?

    private init() {
        loadTemplates()
        setupDefaultTemplateIfNeeded()
    }

    // MARK: - CRUD Operations

    func loadTemplates() {
        let fetchRequest: NSFetchRequest<TemplateEntity> = TemplateEntity.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \TemplateEntity.isDefault, ascending: false),
            NSSortDescriptor(keyPath: \TemplateEntity.dateModified, ascending: false)
        ]

        do {
            let entities = try context.fetch(fetchRequest)
            templates = entities.compactMap { entity in
                entity.toTemplate()
            }

            // Set selected template to default or first available
            if selectedTemplate == nil {
                selectedTemplate = templates.first { $0.isDefault } ?? templates.first
            }
        } catch {
            print("Error loading templates: \(error)")
        }
    }

    func createTemplate(name: String, questions: [Question], isDefault: Bool = false) {
        let template = Template(
            name: name,
            questions: questions,
            isDefault: isDefault
        )

        saveTemplateToCore(template)
    }

    func updateTemplate(_ template: Template) {
        let fetchRequest: NSFetchRequest<TemplateEntity> = TemplateEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", template.id as CVarArg)

        do {
            let entities = try context.fetch(fetchRequest)
            if let entity = entities.first {
                entity.name = template.name
                entity.questionsData = try JSONEncoder().encode(template.questions)
                entity.dateModified = Date()
                entity.isDefault = template.isDefault

                try context.save()
                loadTemplates()
            }
        } catch {
            print("Error updating template: \(error)")
        }
    }

    func deleteTemplate(_ template: Template) {
        let fetchRequest: NSFetchRequest<TemplateEntity> = TemplateEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", template.id as CVarArg)

        do {
            let entities = try context.fetch(fetchRequest)
            if let entity = entities.first {
                context.delete(entity)
                try context.save()
                loadTemplates()

                // If deleted template was selected, select another
                if selectedTemplate?.id == template.id {
                    selectedTemplate = templates.first
                }
            }
        } catch {
            print("Error deleting template: \(error)")
        }
    }

    func selectTemplate(_ template: Template) {
        selectedTemplate = template
        UserDefaults.standard.set(template.id.uuidString, forKey: "selectedTemplateID")
    }

    // MARK: - Import/Export

    func importTemplate(_ template: Template) -> Bool {
        // Check if template with same ID already exists
        let fetchRequest: NSFetchRequest<TemplateEntity> = TemplateEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", template.id as CVarArg)

        do {
            let existing = try context.fetch(fetchRequest)
            if !existing.isEmpty {
                // Template already exists, create a copy with new ID
                var newTemplate = template
                newTemplate.id = UUID()
                newTemplate.name = "\(template.name) (Copy)"
                newTemplate.isDefault = false
                saveTemplateToCore(newTemplate)
            } else {
                // Save as-is but not as default
                var importedTemplate = template
                importedTemplate.isDefault = false
                saveTemplateToCore(importedTemplate)
            }
            return true
        } catch {
            print("Error importing template: \(error)")
            return false
        }
    }

    func exportTemplate(_ template: Template) -> String? {
        return template.toShareableString()
    }

    // MARK: - Private Helpers

    private func saveTemplateToCore(_ template: Template) {
        let entity = TemplateEntity(context: context)
        entity.id = template.id
        entity.name = template.name
        entity.dateCreated = template.dateCreated
        entity.dateModified = template.dateModified
        entity.isDefault = template.isDefault

        do {
            entity.questionsData = try JSONEncoder().encode(template.questions)
            try context.save()
            loadTemplates()
        } catch {
            print("Error saving template: \(error)")
        }
    }

    private func setupDefaultTemplateIfNeeded() {
        if templates.isEmpty {
            createTemplate(
                name: "Home Health Visit",
                questions: Question.homeHealthQuestions,
                isDefault: true
            )
        }

        // Restore selected template from UserDefaults
        if let savedID = UserDefaults.standard.string(forKey: "selectedTemplateID"),
           let uuid = UUID(uuidString: savedID),
           let template = templates.first(where: { $0.id == uuid }) {
            selectedTemplate = template
        }
    }
}

// MARK: - Core Data Entity Extension

@objc(TemplateEntity)
public class TemplateEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var questionsData: Data?
    @NSManaged public var dateCreated: Date?
    @NSManaged public var dateModified: Date?
    @NSManaged public var isDefault: Bool

    func toTemplate() -> Template? {
        guard let id = id,
              let name = name,
              let questionsData = questionsData,
              let dateCreated = dateCreated,
              let dateModified = dateModified,
              let questions = try? JSONDecoder().decode([Question].self, from: questionsData) else {
            return nil
        }

        return Template(
            id: id,
            name: name,
            questions: questions,
            dateCreated: dateCreated,
            dateModified: dateModified,
            isDefault: isDefault
        )
    }
}

extension TemplateEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TemplateEntity> {
        return NSFetchRequest<TemplateEntity>(entityName: "TemplateEntity")
    }
}
