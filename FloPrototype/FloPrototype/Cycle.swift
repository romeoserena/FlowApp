//
//  Cycle.swift
//  FloPrototype
//
//  Created by serena romeo on 07/11/25.
//

import Foundation

struct Cycle: Identifiable, Codable, Equatable {
    let id: UUID
    var startDate: Date
    var endDate: Date?

    init(id: UUID = UUID(), startDate: Date, endDate: Date? = nil) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
    }

    var lengthInDays: Int? {
        guard let endDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: startDate), to: Calendar.current.startOfDay(for: endDate)).day
    }
}
