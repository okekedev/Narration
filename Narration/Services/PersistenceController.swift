//
//  PersistenceController.swift
//  Narration
//
//  Created by Claude on 10/28/25.
//

import CoreData
import CloudKit

@MainActor
class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Narration")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure CloudKit
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("Could not retrieve persistent store description")
            }

            // Enable CloudKit sync
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.narration.app"
            )

            // Enable persistent history tracking for CloudKit
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // Replace this implementation with proper error handling
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        // Automatically merge changes from CloudKit
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }

    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
