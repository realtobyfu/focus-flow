//
//  ContentView.swift
//  Focus Flow
//
//  Created by Tobias Fu on 3/2/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @State private var showingAddTaskView = false

    var body: some View {
        NavigationView {
            VStack {
                if $taskViewModel.tasks.isEmpty {
                    Text("No tasks yet!")
                        .foregroundColor(.secondary)
                } else {
                    List {
                        ForEach(taskViewModel.tasks) { task in
                            NavigationLink(destination: TimerView(task: task)) {
                                TaskRowView(task: task)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("FocusFlow")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTaskView = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTaskView) {
            AddTaskView()
        }
    }

    func delete(at offsets: IndexSet) {
        offsets.map { taskViewModel.tasks[$0] }.forEach { task in
            taskViewModel.deleteTask(task)
        }
    }
}
