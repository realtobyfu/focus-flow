import SwiftUI

struct EnhancedStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let theme: EnvironmentalTheme
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon with animated glow
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .opacity(isAnimating ? 0.7 : 1.0)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: theme.gradientColors.first?.opacity(0.2) ?? .clear,
            radius: 10,
            x: 0,
            y: 5
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// Enhanced Weekly Progress Chart with Glass Morphism
struct EnhancedWeeklyProgressChart: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    let theme: EnvironmentalTheme
    
    let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Weekly Progress")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if getWeeklyTotal() > 0 {
                    Text("\(getWeeklyTotal()) min total")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(theme.gradientColors.first?.opacity(0.3) ?? .clear)
                        )
                }
            }
            
            // Chart with glass morphism
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<weekdays.count, id: \.self) { index in
                    let focusMinutes = taskViewModel.weeklyStats()[index]
                    let isToday = Calendar.current.component(.weekday, from: Date()) == convertToWeekdayIndex(index)
                    
                    VStack(spacing: 8) {
                        // Value label
                        if focusMinutes > 0 {
                            Text("\(focusMinutes)")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .opacity(0.8)
                        }
                        
                        // Bar
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: isToday ? theme.gradientColors : [Color.white.opacity(0.3), Color.white.opacity(0.2)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 35, height: barHeight(for: focusMinutes))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        
                        // Day label
                        Text(weekdays[index])
                            .font(.caption2)
                            .foregroundColor(isToday ? .white : .white.opacity(0.7))
                            .fontWeight(isToday ? .bold : .regular)
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func barHeight(for minutes: Int) -> CGFloat {
        let maxHeight: CGFloat = 120
        let maxMinutes = taskViewModel.weeklyStats().max() ?? 1
        guard maxMinutes > 0 else { return 5 }
        return max(5, CGFloat(minutes) / CGFloat(maxMinutes) * maxHeight)
    }
    
    private func convertToWeekdayIndex(_ ourIndex: Int) -> Int {
        return ourIndex == 6 ? 1 : ourIndex + 2
    }
    
    private func getWeeklyTotal() -> Int {
        return taskViewModel.weeklyStats().reduce(0, +)
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "56CCF2"), Color(hex: "2F80ED")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: 20) {
            HStack(spacing: 15) {
                EnhancedStatCard(
                    icon: "calendar",
                    title: "Today",
                    value: "2h 30m",
                    color: .orange,
                    theme: EnvironmentalTheme.productiveSky
                )
                
                EnhancedStatCard(
                    icon: "calendar.badge.clock",
                    title: "This Week",
                    value: "15h 45m",
                    color: .blue,
                    theme: EnvironmentalTheme.productiveSky
                )
            }
            .padding(.horizontal)
            
            EnhancedWeeklyProgressChart(theme: EnvironmentalTheme.productiveSky)
                .padding(.horizontal)
        }
    }
    .environmentObject(TaskViewModel(context: PersistenceController.preview.container.viewContext))
}