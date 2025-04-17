//
//  TaskViewModel.swift
//  Focus Flow
//
//  Created by Tobias Fu on 3/2/25.
//

import SwiftUI
import CoreData

class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskEntity] = []
    
    private let context: NSManagedObjectContext

    // Pass in the Core Data context from your App file
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchTasks()
    }

    // Fetch all TaskEntity objects from the store
    func fetchTasks() {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        // Optionally sort by dateCreated descending
        request.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: false)]
        
        do {
            tasks = try context.fetch(request)
        } catch {
            print("Failed to fetch tasks: \(error)")
        }
    }
    
    // Create and save a new TaskEntity
    func addTask(title: String,
                 totalMinutes: Int64,
                 blockMinutes: Int64,
                 breakMinutes: Int64) {
        let newTask = TaskEntity(context: context)
        newTask.id = UUID()
        newTask.title = title
        newTask.totalMinutes = totalMinutes
        newTask.blockMinutes = blockMinutes
        newTask.breakMinutes = breakMinutes
        newTask.completionPercentage = 0
        newTask.dateCreated = Date()
        
        saveContext()
        fetchTasks()
    }

    // Delete an existing TaskEntity
    func removeTask(_ task: TaskEntity) {
        context.delete(task)
        saveContext()
        fetchTasks()
    }

    // Example method to update completion or anything else
    func updateTask(_ task: TaskEntity, completion: Double) {
        task.completionPercentage = completion
        saveContext()
        fetchTasks()
    }
    
    // MARK: - Core Data Save
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Failed to save: \(error)")
        }
    }
}
