//
//  WeeklyProgressChart.swift
//  Focus Flow
//
//  Created by Tobias Fu on 4/25/25.
//

import Foundation
import SwiftUI

struct WeeklyProgressChart: View {
    let themeColor: Color
    
    let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    let focusMinutes = [45, 60, 30, 75, 25, 10, 50]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(0..<weekdays.count, id: \.self) { index in
                BarColumn(
                    day: weekdays[index],
                    minutes: focusMinutes[index],
                    isToday: Date().dayOfWeek == index + 1,
                    themeColor: themeColor
                )
            }
        }
        .padding(.horizontal)
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
            // Bar
            RoundedRectangle(cornerRadius: 4)
                .fill(barColor)
                .frame(width: 30, height: barHeight)
            
            // Day label
            Text(day)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var barColor: Color {
        themeColor.opacity(isToday ? 1.0 : 0.7)
    }
    
    private var barHeight: CGFloat {
        max(20, CGFloat(minutes) * 1.5)
    }
}


extension Date {
    var dayOfWeek: Int {
        return Calendar.current.component(.weekday, from: self)
    }
}
