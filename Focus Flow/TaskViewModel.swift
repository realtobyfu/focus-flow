//
//  TaskViewModel.swift
//  Focus Flow
//
//  Created by Tobias Fu on 3/2/25.
//

import SwiftUI

class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskEntity] = [] {
        didSet {
            saveTasksToUserDefaults()
        }
    }
    
    private let tasksKey = "storedTasks"

    init() {
        loadTasksFromUserDefaults()
    }
    
    func addTask(_ task: TaskEntity) {
        tasks.append(task)
    }
    
    func removeTask(_ task: TaskEntity) {
        tasks.removeAll { $0.id == task.id }
    }
    
    func updateTask(_ task: TaskEntity) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index] = task
    }
    
    func loadTasksFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([TaskEntity].self, from: data) {
            tasks = decoded
        }
    }
    
    func saveTasksToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: tasksKey)
        }
    }
}
