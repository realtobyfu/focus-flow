//
//  StatisticCard.swift
//  Focus Flow
//
//  Created by Tobias Fu on 4/25/25.
//
import Foundation
import SwiftUI

// Statistic Card Component
struct StatisticCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.35))
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
}

// Circular Statistic Component
struct StatCircle: View {
    let value: Double
    let label: String
    let color: Color
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: CGFloat(min(value, 100)) / 100.0)
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut, value: value)
                
                VStack(spacing: 2) {
                    Text("\(Int(value))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                }
            }
            
            Text(label)
                .font(.footnote)
                .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.35))
                .padding(.top, 5)
        }
        .frame(maxWidth: .infinity)
    }
}
