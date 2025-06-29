//
//  Persistence.swift
//  Focus Flow
//
//  Created by Tobias Fu on 3/2/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    // Preview instance for SwiftUI previews
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        for i in 0..<3 {
            let newTask = TaskEntity(context: viewContext)
            newTask.id = UUID()
            newTask.title = "Sample Task \(i + 1)"
            newTask.totalMinutes = 50
            newTask.blockMinutes = 25
            newTask.breakMinutes = 5
            newTask.dateCreated = Date()
            newTask.completionPercentage = Double(i * 30)
            newTask.tag = ["Focus", "Study", "Work"][i]
        }
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
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
