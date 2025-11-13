//
//  CalendarView.swift
//  FloPrototype
//
//  Created by serena romeo on 07/11/25.
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var store: CycleStore
    @State private var selectedDate: Date? = Date()
    @State private var showingEditor = false

    // Configure range (e.g., 24 months back/forward)
    private let monthsBack = 24
    private let monthsForward = 24

    private var months: [Date] {
        let cal = Calendar.current
        let start = cal.date(byAdding: .month, value: -monthsBack, to: Date())!
        return (0...(monthsBack + monthsForward)).compactMap { offset in
            cal.date(byAdding: .month, value: offset, to: cal.startOfMonth(for: start))
        }
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        ForEach(months, id: \.self) { month in
                            MonthSection(month: month,
                                         selectedDate: $selectedDate,
                                         onSelect: { date in
                                selectedDate = date
                                showingEditor = true
                            })
                            .id(month)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .onAppear {
                    // Scroll to current month on first appear
                    DispatchQueue.main.async {
                        proxy.scrollTo(Calendar.current.startOfMonth(for: Date()), anchor: .top)
                    }
                }
            }
            .navigationTitle("Calendar")
            .sheet(isPresented: $showingEditor) {
                if let date = selectedDate {
                    DayEditorSheet(date: date)
                        .environmentObject(store)
                        .presentationDetents([.height(420), .medium])
                }
            }
        }
    }
}

private struct MonthSection: View {
    let month: Date
    @Binding var selectedDate: Date?
    var onSelect: (Date) -> Void

    @EnvironmentObject private var store: CycleStore

    private var title: String {
        month.formatted(.dateTime.year().month())
    }

    private var days: [Date?] {
        // Build the 7xN grid with leading blanks
        let cal = Calendar.current
        let daysInMonth = cal.daysInMonth(for: month)
        let offset = cal.firstWeekdayOffsetInMonth(for: month)
        var cells: [Date?] = Array(repeating: nil, count: offset)
        let start = cal.startOfMonth(for: month)
        for i in 0..<daysInMonth {
            if let d = cal.date(byAdding: .day, value: i, to: start) {
                cells.append(d)
            }
        }
        return cells
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 4)

            // Weekday headers (localized first letters)
            let symbols = Calendar.current.shortStandaloneWeekdaySymbols
            let reordered = Array(symbols[Calendar.current.firstWeekday-1..<symbols.count]) + Array(symbols[0..<Calendar.current.firstWeekday-1])

            HStack {
                ForEach(reordered, id: \.self) { s in
                    Text(s.uppercased().prefix(1))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)

            // Grid 7 columns
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                ForEach(days.indices, id: \.self) { idx in
                    if let date = days[idx] {
                        DayCell(date: date, isSelected: Binding(
                            get: { selectedDate.map { Calendar.current.isDateSameDay($0, date) } ?? false },
                            set: { newValue in
                                if newValue { onSelect(date) } else { selectedDate = nil }
                            }
                        ))
                        .environmentObject(store)
                        .onTapGesture {
                            onSelect(date)
                        }
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
    }
}

private struct DayCell: View {
    @EnvironmentObject private var store: CycleStore
    let date: Date
    @Binding var isSelected: Bool

    private var annotation: DayAnnotation? { store.annotation(for: date) }
    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    var body: some View {
        let number = Calendar.current.component(.day, from: date)
        VStack(spacing: 2) {
            ZStack {
                // Selection background
                if isSelected {
                    Circle()
                        .fill(Color.pink.opacity(0.15))
                        .frame(width: 38, height: 38)
                }

                // Dotted ring for period days
                if let idx = annotation?.periodDayIndex {
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
                        .foregroundStyle(Color.pink)
                        .frame(width: 34, height: 34)

                    if idx > 0 && idx <= 31 {
                        Text("\(number)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                }

                // Today indicator (teal dotted ring when not a period day)
                if annotation?.periodDayIndex == nil, isToday {
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
                        .foregroundStyle(Color.teal)
                        .frame(width: 34, height: 34)
                }

                // Day number
                Text("\(number)")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.primary)
            }
            .frame(height: 38)

            // Symptom dots row (up to 3)
            HStack(spacing: 2) {
                ForEach(Array((annotation?.symptoms ?? []).prefix(3).enumerated()), id: \.offset) { _ in
                    Circle().fill(Color.pink).frame(width: 4, height: 4)
                }
            }
            .frame(height: 6)
        }
        .frame(height: 40)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts: [String] = []
        parts.append(date.formatted(date: .long, time: .omitted))
        if let idx = annotation?.periodDayIndex {
            parts.append("Period day \(idx)")
        }
        if let count = annotation?.symptoms.count, count > 0 {
            parts.append("\(count) symptoms")
        }
        if parts.count == 1, isToday { parts.append("Today") }
        return parts.joined(separator: ", ")
    }
}

private struct DayEditorSheet: View {
    @EnvironmentObject private var store: CycleStore
    let date: Date

    @Environment(\.dismiss) private var dismiss

    private let quickDays = Array(1...7)

    var body: some View {
        NavigationStack {
            Form {
                Section(date.formatted(date: .complete, time: .omitted)) {
                    // Quick period day picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            Button {
                                store.setPeriodDay(nil, for: date)
                            } label: {
                                Label("None", systemImage: "nosign")
                            }
                            .buttonStyle(.bordered)

                            ForEach(quickDays, id: \.self) { d in
                                Button("Day \(d)") {
                                    store.setPeriodDay(d, for: date)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                }

                // Symptoms
                Section("Symptoms") {
                    let current = store.annotation(for: date)?.symptoms ?? []
                    ForEach(Symptom.allCases) { s in
                        Button {
                            store.toggle(symptom: s, for: date)
                        } label: {
                            HStack {
                                Text(s.displayName)
                                Spacer()
                                if current.contains(s) {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.pink)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Day")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(CycleStore())
}
