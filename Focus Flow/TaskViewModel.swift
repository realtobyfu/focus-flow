//
//  TaskViewModel.swift
//  Focus Flow
//
//  Created by Tobias Fu on 3/2/25.
//

import SwiftUI
import CoreData

// Enum for task filtering
enum TaskFilterMode: String {
    case all = "All Tasks"
    case inProgress = "In Progress"
    case completed = "Completed"
}

class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskEntity] = []
    @Published var filterMode: TaskFilterMode = .all
    
    private let context: NSManagedObjectContext
    
    // Computed properties for statistics
    var completedTasks: Int {
        tasks.filter { $0.completionPercentage >= 100 }.count
    }
    
    var inProgressTasks: Int {
        tasks.filter { $0.completionPercentage > 0 && $0.completionPercentage < 100 }.count
    }
    
    var totalFocusTime: String {
        let minutes = tasks.reduce(0) { $0 + ($1.completionPercentage / 100.0 * Double($1.totalMinutes)) }
        if minutes >= 60 {
            let hours = Int(minutes / 60)
            let remainingMinutes = Int(minutes.truncatingRemainder(dividingBy: 60))
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(Int(minutes))m"
        }
    }
    
    var completedTasksPercentage: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedTasks) / Double(tasks.count) * 100
    }
    
    // Filtered tasks based on selected filter mode
    var filteredTasks: [TaskEntity] {
        switch filterMode {
        case .all:
            return tasks
        case .inProgress:
            return tasks.filter { $0.completionPercentage < 100 }
        case .completed:
            return tasks.filter { $0.completionPercentage >= 100 }
        }
    }
    
    // Weekly task statistics - returns minutes per weekday (1-7)
    func weeklyStats() -> [Int] {
        let calendar = Calendar.current
        var stats = [Int](repeating: 0, count: 7)
        
        // Get start of current week
        let today = Date()
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return stats
        }
        
        for task in tasks {
            guard let dateCreated = task.dateCreated else { continue }
            
            // Only count tasks from this week
            if let daysSinceStart = calendar.dateComponents([.day], from: startOfWeek, to: dateCreated).day,
               daysSinceStart >= 0 && daysSinceStart < 7 {
                
                // Calculate completed minutes based on completion percentage
                let completedMinutes = Int(Double(task.totalMinutes) * task.completionPercentage / 100.0)
                stats[daysSinceStart] += completedMinutes
            }
        }
        
        return stats
    }

    // Pass in the Core Data context from your App file
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchTasks()
    }

    // Fetch all TaskEntity objects from the store
    func fetchTasks() {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        // Sort by dateCreated descending (newest first)
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

    // Update task completion
    func updateTask(_ task: TaskEntity, completion: Double) {
        task.completionPercentage = min(completion, 100)
        saveContext()
        fetchTasks()
    }
    
    // Update task completion incrementally based on completed time
    func updateTaskProgress(_ task: TaskEntity, completedMinutes: Int64) {
        // Calculate how much of the total time this completed segment represents
        let percentageIncrement = (Double(completedMinutes) / Double(task.totalMinutes)) * 100
        
        // Add to current completion percentage, cap at 100%
        let newPercentage = min(task.completionPercentage + percentageIncrement, 100)
        task.completionPercentage = newPercentage
        
        saveContext()
        fetchTasks()
    }
    
    // Reset a task to 0% completion
    func resetTask(_ task: TaskEntity) {
        task.completionPercentage = 0
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
