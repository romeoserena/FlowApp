//
//  AdviceView.swift
//  FloPrototype
//
//  Created by serena romeo on 07/11/25.
//

import SwiftUI

struct AdviceView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("General Tips") {
                    Text("Stay hydrated and maintain a balanced diet.")
                    Text("Track your cycles to understand your patterns.")
                    Text("Light exercise can help with symptoms.")
                }
                Section("Disclaimer") {
                    Text("This app provides general information and is not a substitute for professional medical advice.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Advice")
        }
    }
}

#Preview {
    AdviceView()
}
