//
//  WeeklyProgressChart.swift
//  Focus Flow
//
//  Created by Tobias Fu on 4/25/25.
//

import Foundation
import SwiftUI

struct WeeklyProgressChart: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    let themeColor: Color
    
    // Day names
    let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    var body: some View {
        VStack(spacing: 8) {
            // Chart
            HStack(alignment: .bottom, spacing: 10) {
                // We use actual data from TaskViewModel
                ForEach(0..<weekdays.count, id: \.self) { index in
                    let focusMinutes = taskViewModel.weeklyStats()[index]
                    
                    BarColumn(
                        day: weekdays[index],
                        minutes: focusMinutes,
                        isToday: Calendar.current.component(.weekday, from: Date()) == convertToWeekdayIndex(index),
                        themeColor: themeColor
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // Legend
            HStack {
                Circle()
                    .fill(themeColor)
                    .frame(width: 8, height: 8)
                
                Text("Minutes of focused work")
                    .font(.caption)
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.35))
                
                Spacer()
                
                if getWeeklyTotal() > 0 {
                    Text("Total: \(getWeeklyTotal()) min")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(themeColor)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // Helper function to convert our zero-based index to Calendar weekday (1-based, where 1 is Sunday)
    private func convertToWeekdayIndex(_ ourIndex: Int) -> Int {
        // Our indices: 0=Mon, 1=Tue, ..., 6=Sun
        // Calendar indices: 1=Sun, 2=Mon, ..., 7=Sat
        return ourIndex == 6 ? 1 : ourIndex + 2
    }
    
    // Calculate total minutes for the week
    private func getWeeklyTotal() -> Int {
        return taskViewModel.weeklyStats().reduce(0, +)
    }
}

// Breaking down the complex view into a simpler component
struct BarColumn: View {
    let day: String
    let minutes: Int
    let isToday: Bool
    let themeColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            // Minutes label (only show if there's data)
            if minutes > 0 {
                Text("\(minutes)")
                    .font(.system(size: 10))
                    .foregroundColor(isToday ? themeColor : Color(red: 0.5, green: 0.4, blue: 0.35))
            }
            
            // Bar
            RoundedRectangle(cornerRadius: 4)
                .fill(barColor)
                .frame(width: 30, height: barHeight)
            
            // Day label
            Text(day)
                .font(.caption)
                .foregroundColor(isToday ? themeColor : Color(red: 0.5, green: 0.4, blue: 0.35))
                .fontWeight(isToday ? .bold : .regular)
        }
        .frame(maxHeight: 180, alignment: .bottom)
    }
    
    private var barColor: Color {
        themeColor.opacity(isToday ? 1.0 : minutes > 0 ? 0.7 : 0.2)
    }
    
    private var barHeight: CGFloat {
        if minutes <= 0 {
            return 20 // Minimum height for empty bar
        } else {
            // Scale the bar height - max 150 for better visualization
            let maxHeight: CGFloat = 150
            let scaleFactor: CGFloat = 1.3
            return min(maxHeight, CGFloat(minutes) * scaleFactor + 20)
        }
    }
}
