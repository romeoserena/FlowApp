//
//  CycleStore.swift
//  FloPrototype
//
//  Created by serena romeo on 07/11/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class CycleStore: ObservableObject {
    @Published private(set) var cycles: [Cycle] = []
    @Published private(set) var annotations: [Date: DayAnnotation] = [:] // startOfDay -> annotation

    // Default average cycle length if insufficient data
    @AppStorage("averageCycleLengthDays") var defaultAverageCycleLengthDays: Int = 28

    init() {
        // Seed with sample data for demo; remove in production or load from persistence.
        seedIfEmpty()
        loadAnnotations()
    }

    // MARK: - Period recording
    func recordPeriod(on date: Date = Date()) {
        // Add a new cycle starting on the given date
        let d = Calendar.current.startOfDay(for: date)
        cycles.insert(Cycle(startDate: d), at: 0)
        // Mark day 1 for convenience
        setPeriodDay(1, for: d)
        save()
    }

    func setEndDate(for cycleID: UUID, endDate: Date) {
        guard let index = cycles.firstIndex(where: { $0.id == cycleID }) else { return }
        cycles[index].endDate = Calendar.current.startOfDay(for: endDate)
        save()
    }

    // MARK: - Predictions
    var averageCycleLengthDays: Int {
        let sorted = cycles.sorted(by: { $0.startDate < $1.startDate })
        guard sorted.count >= 2 else { return defaultAverageCycleLengthDays }

        // Compute intervals between consecutive start dates
        var intervals: [Int] = []
        for i in 1..<sorted.count {
            let d = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: sorted[i - 1].startDate), to: Calendar.current.startOfDay(for: sorted[i].startDate)).day ?? 0
            if d > 0 { intervals.append(d) }
        }
        let avg = intervals.isEmpty ? defaultAverageCycleLengthDays : Int(Double(intervals.reduce(0, +)) / Double(intervals.count))
        return max(15, min(60, avg)) // clamp to reasonable range
    }

    var predictedNextPeriodStart: Date? {
        guard let mostRecent = cycles.sorted(by: { $0.startDate > $1.startDate }).first?.startDate else {
            return Calendar.current.date(byAdding: .day, value: defaultAverageCycleLengthDays, to: Calendar.current.startOfDay(for: Date()))
        }
        return Calendar.current.date(byAdding: .day, value: averageCycleLengthDays, to: Calendar.current.startOfDay(for: mostRecent))
    }

    var daysUntilNextPeriod: Int? {
        guard let next = predictedNextPeriodStart else { return nil }
        let today = Calendar.current.startOfDay(for: Date())
        let comps = Calendar.current.dateComponents([.day], from: today, to: Calendar.current.startOfDay(for: next))
        return comps.day
    }

    // MARK: - Day annotations (period day index + symptoms)
    func annotation(for date: Date) -> DayAnnotation? {
        annotations[date.startOfDayLocal]
    }

    func setPeriodDay(_ index: Int?, for date: Date) {
        let key = date.startOfDayLocal
        var value = annotations[key] ?? DayAnnotation()
        value.periodDayIndex = index
        persistAnnotation(value, forKey: key)
        objectWillChange.send()
    }

    func toggle(symptom: Symptom, for date: Date) {
        let key = date.startOfDayLocal
        var value = annotations[key] ?? DayAnnotation()
        if value.symptoms.contains(symptom) {
            value.symptoms.removeAll { $0 == symptom }
        } else {
            value.symptoms.append(symptom)
        }
        persistAnnotation(value, forKey: key)
        objectWillChange.send()
    }

    private func persistAnnotation(_ value: DayAnnotation, forKey key: Date) {
        if value.isEmpty {
            annotations.removeValue(forKey: key)
        } else {
            annotations[key] = value
        }
        saveAnnotations()
    }

    // MARK: - Persistence
    private let storageKey = "cycles_storage_v1"
    private let annotationsKey = "day_annotations_v1"

    private func save() {
        do {
            let data = try JSONEncoder().encode(cycles)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            // In a real app, handle error (logging)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            cycles = try JSONDecoder().decode([Cycle].self, from: data)
        } catch {
            // In a real app, handle error (logging)
        }
    }

    private func saveAnnotations() {
        do {
            // Convert Date keys to ISO strings for JSON
            let iso = ISO8601DateFormatter()
            let payload = annotations.reduce(into: [String: DayAnnotation]()) { dict, pair in
                dict[iso.string(from: pair.key)] = pair.value
            }
            let data = try JSONEncoder().encode(payload)
            UserDefaults.standard.set(data, forKey: annotationsKey)
        } catch {
            // handle error
        }
    }

    private func loadAnnotations() {
        guard let data = UserDefaults.standard.data(forKey: annotationsKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([String: DayAnnotation].self, from: data)
            let iso = ISO8601DateFormatter()
            var map: [Date: DayAnnotation] = [:]
            for (k, v) in decoded {
                if let date = iso.date(from: k) {
                    map[Calendar.current.startOfDay(for: date)] = v
                }
            }
            self.annotations = map
        } catch {
            // handle error
        }
    }

    private func seedIfEmpty() {
        load()
        guard cycles.isEmpty else { return }
        // Seed with a few past cycles spaced ~28 days apart
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let starts = [-84, -56, -28].compactMap { cal.date(byAdding: .day, value: $0, to: today) }
        self.cycles = starts.reversed().map { Cycle(startDate: $0) }
        save()
    }
}
