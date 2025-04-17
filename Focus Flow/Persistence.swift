//
//  Persistence.swift
//  Focus Flow
//
//  Created by Tobias Fu on 3/2/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // Must match "Focus_Flow" if that's the .xcdatamodeld filename:
        container = NSPersistentContainer(name: "Focus_Flow")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        }
        
        // Merge changes from multiple contexts automatically
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
