import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var taskViewModel: TaskViewModel
    
    @State private var taskTitle = ""
    @State private var selectedTag = "Focus"
    @State private var focusDuration = 25
    @State private var breakDuration = 5
    @State private var totalDuration = 50
    @State private var showingNewTag = false
    @State private var newTagName = ""
    @State private var selectedColor = Color.orange
    
    let tags = [
        ("Focus", Color.orange),
        ("Study", Color.teal),
        ("Work", Color.green),
        ("Read", Color.yellow),
        ("Fitness", Color.orange)
    ]
    
    let durations = [15, 25, 30, 45, 50, 60, 90]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Warm beige background
                Color(red: 0.96, green: 0.93, blue: 0.88)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Task Name
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Task Name")
                                .font(.headline)
                                .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                            
                            TextField("What are you working on?", text: $taskTitle)
                                .font(.body)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                )
                        }
                        
                        // Tag Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select Tag")
                                .font(.headline)
                                .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                            
                            VStack(spacing: 12) {
                                ForEach(tags, id: \.0) { tag, color in
                                    TagSelectionRow(
                                        name: tag,
                                        color: color,
                                        isSelected: selectedTag == tag,
                                        action: { selectedTag = tag }
                                    )
                                }
                                
                                // New Tag Button
                                Button(action: { showingNewTag = true }) {
                                    HStack {
                                        Image(systemName: "lock.fill")
                                            .font(.body)
                                        
                                        Text("New Tag")
                                            .font(.body)
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                    }
                                    .foregroundColor(.primary)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color(red: 0.85, green: 0.5, blue: 0.4))
                                    )
                                }
                            }
                        }
                        
                        // Duration Settings
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Duration Settings")
                                .font(.headline)
                                .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                            
                            // Focus Duration
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Focus Duration")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    ForEach([15, 25, 45, 60], id: \.self) { duration in
                                        DurationButton(
                                            duration: duration,
                                            isSelected: focusDuration == duration,
                                            action: { focusDuration = duration }
                                        )
                                    }
                                }
                            }
                            
                            // Break Duration
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Break Duration")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    ForEach([5, 10, 15], id: \.self) { duration in
                                        DurationButton(
                                            duration: duration,
                                            isSelected: breakDuration == duration,
                                            action: { breakDuration = duration }
                                        )
                                    }
                                }
                            }
                            
                            // Total Duration
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Total Duration")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Picker("Total Duration", selection: $totalDuration) {
                                    ForEach(durations, id: \.self) { duration in
                                        Text("\(duration) min").tag(duration)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        
                        // Intervals Preview
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Session Preview")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "repeat")
                                    .foregroundColor(AppTheme.Colors.primary)
                                Text("\(calculateIntervals()) focus intervals")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.5))
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createTask()
                    }
                    .disabled(taskTitle.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingNewTag) {
            NewTagView(tagName: $newTagName, selectedColor: $selectedColor)
        }
    }
    
    private func calculateIntervals() -> Int {
        max(1, totalDuration / (focusDuration + breakDuration))
    }
    
    private func createTask() {
        taskViewModel.createTask(
            title: taskTitle,
            totalMinutes: Int64(totalDuration),
            blockMinutes: Int64(focusDuration),
            breakMinutes: Int64(breakDuration),
            tag: selectedTag
        )
        dismiss()
    }
}

// MARK: - Tag Selection Row
struct TagSelectionRow: View {
    let name: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(color)
                    .frame(width: 16, height: 16)
                
                Text(name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(color)
                }
            }
            .foregroundColor(.primary)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? color.opacity(0.2) : Color.white)
            )
        }
    }
}

// MARK: - Duration Button
struct DurationButton: View {
    let duration: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(duration)")
                .font(.body)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(minWidth: 60)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? AppTheme.Colors.primary : Color.white)
                )
        }
    }
}

// MARK: - New Tag View
struct NewTagView: View {
    @Binding var tagName: String
    @Binding var selectedColor: Color
    @Environment(\.dismiss) private var dismiss
    
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .brown]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.96, green: 0.93, blue: 0.88)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Tag Name Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tag Name")
                            .font(.headline)
                        
                        TextField("Enter tag name", text: $tagName)
                            .font(.body)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                            )
                    }
                    
                    // Color Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Color")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                            ForEach(colors, id: \.self) { color in
                                Button(action: { selectedColor = color }) {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            selectedColor == color ?
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.primary)
                                                .font(.headline) : nil
                                        )
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save tag logic here
                        dismiss()
                    }
                    .disabled(tagName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddTaskView()
        .environmentObject(TaskViewModel(context: PersistenceController.preview.container.viewContext))
}