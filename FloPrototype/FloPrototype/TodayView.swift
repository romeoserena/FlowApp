//
//  TodayView.swift
//  FloPrototype
//
//  Created by serena romeo on 07/11/25.
//

import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: CycleStore
    @State private var showDatePicker = false
    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Next Period")
                            .font(.headline)

                        if let days = store.daysUntilNextPeriod, let next = store.predictedNextPeriodStart {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("\(max(0, days))")
                                    .font(.system(size: 44, weight: .bold, design: .rounded))
                                Text(days == 1 ? "day" : "days")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                            Text("Estimated: \(next.formatted(date: .abbreviated, time: .omitted))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Add a period to start predictions.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Button {
                            showDatePicker = true
                            selectedDate = Date()
                        } label: {
                            Label("Record Period", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 8)
                }

                Section("My Cycles") {
                    if store.cycles.isEmpty {
                        Text("No cycles recorded yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.cycles) { cycle in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Start: \(cycle.startDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.body)
                                if let end = cycle.endDate {
                                    Text("End: \(end.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                if let len = cycle.lengthInDays {
                                    Text("Length: \(len) days")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Today")
            .sheet(isPresented: $showDatePicker) {
                RecordPeriodSheet(selectedDate: $selectedDate) {
                    store.recordPeriod(on: selectedDate)
                }
                .presentationDetents([.height(340), .medium])
            }
        }
    }
}

private struct RecordPeriodSheet: View {
    @Binding var selectedDate: Date
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Period start", selection: $selectedDate, displayedComponents: .date)
            }
            .navigationTitle("Record Period")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}

#Preview("TodayView - Seeded") {
    let store = CycleStore()
    // Seed a recent period so predictions are visible in the preview
    let cal = Calendar.current
    if let twentyDaysAgo = cal.date(byAdding: .day, value: -20, to: Date()) {
        store.recordPeriod(on: twentyDaysAgo)
        // Optionally set an end date 5 days after the start to show length
        if let end = cal.date(byAdding: .day, value: 5, to: twentyDaysAgo),
           let last = store.cycles.first {
            store.setEndDate(for: last.id, endDate: end)
        }
    }
    return TodayView()
        .environmentObject(store)
}
