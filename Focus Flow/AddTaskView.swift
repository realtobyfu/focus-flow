//
//  AddTaskView.swift
//  Focus Flow
//
//  Created by Tobias Fu on 3/8/25.
//

import SwiftUI

struct TaskRowView: View {
    @ObservedObject var task: TaskEntity  // NSManagedObject

    var body: some View {
        VStack(alignment: .leading) {
            Text(task.title ?? "Untitled")
                .font(.headline)
            
            HStack {
                Text("Progress:")
                ProgressView(value: task.completionPercentage, total: 100)
                    .frame(width: 100)
                Text("\(Int(task.completionPercentage))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AddTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var totalMinutes: Int64 = 60
    @State private var blockMinutes: Int64 = 25
    @State private var breakMinutes: Int64 = 5
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task Name", text: $title)
                    Stepper("Total Time (min): \(totalMinutes)", value: $totalMinutes, in: 1...480)
                    Stepper("Focus Block (min): \(blockMinutes)", value: $blockMinutes, in: 1...180)
                    Stepper("Break (min): \(breakMinutes)", value: $breakMinutes, in: 1...60)
                }
            }
            .navigationTitle("Add Task")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addNewTask()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func addNewTask() {
        let newTask = TaskEntity(context: viewContext)
        newTask.id = UUID()
        newTask.title = title
        newTask.totalMinutes = totalMinutes
        newTask.blockMinutes = blockMinutes
        newTask.breakMinutes = breakMinutes
        newTask.completionPercentage = 0.0
        newTask.dateCreated = Date()
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save new task: \(error)")
        }
    }
}
