//
//  DayAnnotation.swift
//  FloPrototype
//
//  Created by serena romeo on 07/11/25.
//

import Foundation

enum Symptom: String, CaseIterable, Codable, Identifiable {
    case cramps
    case headache
    case mood
    case bloating
    case acne

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .cramps: return "Cramps"
        case .headache: return "Headache"
        case .mood: return "Mood"
        case .bloating: return "Bloating"
        case .acne: return "Acne"
        }
    }
}

struct DayAnnotation: Codable, Equatable {
    // nil = not a period day; 1 = first day, 2 = second day, etc.
    var periodDayIndex: Int?
    var symptoms: [Symptom]

    init(periodDayIndex: Int? = nil, symptoms: [Symptom] = []) {
        self.periodDayIndex = periodDayIndex
        self.symptoms = symptoms
    }

    var isEmpty: Bool {
        periodDayIndex == nil && symptoms.isEmpty
    }
}
