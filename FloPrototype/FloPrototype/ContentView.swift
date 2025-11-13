//
//  ContentView.swift
//  FloPrototype
//
//  Created by serena romeo on 07/11/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = CycleStore()

    var body: some View {
        ZStack {
            Color.pink
                .ignoresSafeArea()
            TabView {
                TodayView()
                    .environmentObject(store)
                    .tabItem {
                        Label("BHO", systemImage: "sun.max")
                    }

                CalendarView()
                    .environmentObject(store)
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }

                AdviceView()
                    .tabItem {
                        Label("Advice", systemImage: "lightbulb")
                    }
            }
            .background(.clear) // Let the pink ZStack show through
        }
    }
}

#Preview {
    ContentView()
}
