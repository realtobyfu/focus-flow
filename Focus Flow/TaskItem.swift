////
////  TaskItem.swift
////  Focus Flow
////
////  Created by Tobias Fu on 3/2/25.
////
//
//import Foundation
//
//struct TaskItem: Identifiable, Codable {
//    let id: UUID
//    var title: String
//    var totalMinutes: Int       // total planned minutes of work
//    var blockMinutes: Int       // length of a single continuous block
//    var breakMinutes: Int       // length of break
//    var totalBlocksCompleted: Int
//    var totalBlocksNeeded: Int {
//        totalMinutes / blockMinutes
//    }
//    
//    init(id: UUID = UUID(),
//         title: String,
//         totalMinutes: Int,
//         blockMinutes: Int,
//         breakMinutes: Int,
//         totalBlocksCompleted: Int = 0) {
//        self.id = id
//        self.title = title
//        self.totalMinutes = totalMinutes
//        self.blockMinutes = blockMinutes
//        self.breakMinutes = breakMinutes
//        self.totalBlocksCompleted = totalBlocksCompleted
//    }
//}
