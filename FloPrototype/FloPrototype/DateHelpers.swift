//
//  DateHelpers.swift
//  FloPrototype
//
//  Created by serena romeo on 07/11/25.
//

import Foundation

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }

    func endOfMonth(for date: Date) -> Date {
        let start = startOfMonth(for: date)
        var comps = DateComponents()
        comps.month = 1
        comps.day = -1
        return self.date(byAdding: comps, to: start) ?? date
    }

    func daysInMonth(for date: Date) -> Int {
        let range = range(of: .day, in: .month, for: startOfMonth(for: date))
        return range?.count ?? 30
    }

    func firstWeekdayOffsetInMonth(for date: Date) -> Int {
        // Number of leading empty cells before the 1st, based on this Calendar's firstWeekday
        let start = startOfMonth(for: date)
        let weekday = component(.weekday, from: start) // 1..7
        // Convert to zero-based offset from firstWeekday
        let offset = (weekday - firstWeekday + 7) % 7
        return offset
    }

    func isDateSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        isDate(lhs, inSameDayAs: rhs)
    }

    func daysBetween(_ from: Date, _ to: Date) -> Int {
        dateComponents([.day], from: startOfDay(for: from), to: startOfDay(for: to)).day ?? 0
    }
}

extension Date {
    var startOfDayLocal: Date { Calendar.current.startOfDay(for: self) }
}
