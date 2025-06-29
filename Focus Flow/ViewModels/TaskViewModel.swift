import SwiftUI
import CoreData

class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskEntity] = []
    @Published var activeTask: TaskEntity?
    @Published var todayMinutes: Int = 0
    @Published var currentStreak: Int = 0
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchTasks()
        calculateTodayStats()
    }
    
    // MARK: - CRUD Operations
    
    func fetchTasks() {
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: false)]
        
        do {
            tasks = try context.fetch(request)
        } catch {
            print("Error fetching tasks: \(error)")
        }
    }
    
    func createTask(title: String, totalMinutes: Int64, blockMinutes: Int64, breakMinutes: Int64, tag: String? = nil) {
        let newTask = TaskEntity(context: context)
        newTask.id = UUID()
        newTask.title = title
        newTask.totalMinutes = totalMinutes
        newTask.blockMinutes = blockMinutes
        newTask.breakMinutes = breakMinutes
        newTask.dateCreated = Date()
        newTask.completionPercentage = 0
        newTask.tag = tag
        
        saveContext()
        fetchTasks()
    }
    
    func createQuickTask(title: String, duration: Int, tag: String) -> TaskEntity {
        let task = TaskEntity(context: context)
        task.id = UUID()
        task.title = title
        task.totalMinutes = Int64(duration)
        task.blockMinutes = Int64(duration)
        task.breakMinutes = 5
        task.dateCreated = Date()
        task.completionPercentage = 0
        task.tag = tag
        
        saveContext()
        fetchTasks()
        return task
    }
    
    func updateTask(_ task: TaskEntity) {
        saveContext()
        fetchTasks()
    }
    
    func deleteTask(_ task: TaskEntity) {
        context.delete(task)
        saveContext()
        fetchTasks()
    }
    
    func startTask(_ task: TaskEntity) {
        activeTask = task
    }
    
    func updateTaskProgress(_ task: TaskEntity, completedMinutes: Int64) {
        let totalIntervals = task.totalMinutes / task.blockMinutes
        let completedIntervals = (task.completionPercentage / 100.0) * Double(totalIntervals)
        let newCompletedIntervals = completedIntervals + 1
        
        task.completionPercentage = min((newCompletedIntervals / Double(totalIntervals)) * 100, 100)
        
        if task.completionPercentage >= 100 {
            task.isCompleted = true
            completeTask(task)
        }
        
        saveContext()
        calculateTodayStats()
    }
    
    private func completeTask(_ task: TaskEntity) {
        // Update streak and stats
        updateDailyStats()
        
        // Check for achievements
        checkAchievements()
    }
    
    // MARK: - Statistics
    
    func calculateTodayStats() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "dateCreated >= %@", today as NSDate)
        
        do {
            let todayTasks = try context.fetch(request)
            todayMinutes = todayTasks.reduce(0) { sum, task in
                sum + Int(Double(task.blockMinutes) * (task.completionPercentage / 100.0))
            }
        } catch {
            print("Error calculating today's stats: \(error)")
        }
    }
    
    func getTodayStats() -> TodayStats {
        calculateTodayStats()
        
        return TodayStats(
            focusProgress: Double(todayMinutes),
            dailyGoal: 120.0, // 2 hours default
            sessionsCompleted: Double(tasks.filter { isToday($0.dateCreated) && $0.completionPercentage >= 100 }.count),
            sessionGoal: 4.0,
            tasksCompleted: tasks.filter { isToday($0.dateCreated) && $0.completionPercentage >= 100 }.count,
            taskGoal: 3,
            currentStreak: currentStreak,
            aiInsight: generateInsight()
        )
    }
    
    private func isToday(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        return Calendar.current.isDateInToday(date)
    }
    
    private func updateDailyStats() {
        // Update UserDefaults for streak tracking
        let defaults = UserDefaults.standard
        let lastCompletionDate = defaults.object(forKey: "lastCompletionDate") as? Date ?? Date.distantPast
        let calendar = Calendar.current
        
        if calendar.isDateInToday(lastCompletionDate) {
            // Already completed today
        } else if calendar.isDateInYesterday(lastCompletionDate) {
            // Continue streak
            currentStreak = defaults.integer(forKey: "currentStreak") + 1
        } else {
            // Reset streak
            currentStreak = 1
        }
        
        defaults.set(Date(), forKey: "lastCompletionDate")
        defaults.set(currentStreak, forKey: "currentStreak")
    }
    
    private func checkAchievements() {
        // Trigger achievement checks
        NotificationCenter.default.post(name: .checkAchievements, object: nil)
    }
    
    private func generateInsight() -> String? {
        if todayMinutes > 120 {
            return "You're on fire! Keep up the great work!"
        } else if todayMinutes > 60 {
            return "Nice progress today. One more session to hit your goal!"
        } else if todayMinutes > 0 {
            return "Great start! Keep the momentum going."
        } else {
            return "Ready to start your first session?"
        }
    }
    
    // MARK: - Weekly Statistics
    
    func weeklyStats() -> [Int] {
        var weekStats = [Int](repeating: 0, count: 7) // Mon-Sun
        let calendar = Calendar.current
        let today = Date()
        
        // Get start of current week (Monday)
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start,
              let monday = calendar.date(byAdding: .day, value: calendar.component(.weekday, from: weekStart) == 1 ? 1 : 2 - calendar.component(.weekday, from: weekStart), to: weekStart) else {
            return weekStats
        }
        
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        
        do {
            let allTasks = try context.fetch(request)
            
            for dayIndex in 0..<7 {
                guard let dayDate = calendar.date(byAdding: .day, value: dayIndex, to: monday) else { continue }
                let dayStart = calendar.startOfDay(for: dayDate)
                guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { continue }
                
                let dayMinutes = allTasks.filter { task in
                    guard let date = task.dateCreated else { return false }
                    return date >= dayStart && date < dayEnd
                }.reduce(0) { sum, task in
                    sum + Int(Double(task.blockMinutes) * (task.completionPercentage / 100.0))
                }
                
                weekStats[dayIndex] = dayMinutes
            }
        } catch {
            print("Error fetching weekly stats: \(error)")
        }
        
        return weekStats
    }
    
    func minutesForMode(_ mode: FocusMode) -> Int {
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        
        do {
            let allTasks = try context.fetch(request)
            
            return allTasks.filter { task in
                // Map task tags to focus modes
                guard let tag = task.tag else { return false }
                return tagMatchesMode(tag: tag, mode: mode)
            }.reduce(0) { sum, task in
                sum + Int(Double(task.blockMinutes) * (task.completionPercentage / 100.0))
            }
        } catch {
            print("Error fetching mode stats: \(error)")
            return 0
        }
    }
    
    private func tagMatchesMode(tag: String, mode: FocusMode) -> Bool {
        switch mode {
        case .deepWork:
            return tag == "Work"
        case .learning:
            return tag == "Study"
        case .mindfulFocus:
            return tag == "Read" || tag == "Focus"
        case .quickSprint:
            return tag == "Fitness"
        case .creativeFlow:
            return tag == "Creative" || tag == "Design"
        }
    }
    
    // MARK: - Core Data
    
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

// MARK: - Models

struct TodayStats {
    let focusProgress: Double
    let dailyGoal: Double
    let sessionsCompleted: Double
    let sessionGoal: Double
    let tasksCompleted: Int
    let taskGoal: Int
    let currentStreak: Int
    let aiInsight: String?
}

// MARK: - TaskEntity Extensions

extension TaskEntity {
    var isCompleted: Bool {
        get { completionPercentage >= 100 }
        set { completionPercentage = newValue ? 100 : completionPercentage }
    }
    
    var estimatedTimeRemaining: Int {
        let remainingPercentage = max(0, 100 - completionPercentage)
        return Int(Double(totalMinutes) * (remainingPercentage / 100.0))
    }
    
    var formattedDateCreated: String {
        guard let date = dateCreated else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let checkAchievements = Notification.Name("checkAchievements")
}