//
//  HomeScreen.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 11.05.2025.
//

import SwiftUI
import SWDesignSystem

struct HomeScreen: View {
    @Environment(StatusManager.self) private var statusManager
    
    var body: some View {
        NavigationStack {
            if let calculator = DayCalculator(statusManager.currentDay) {
                ScrollView {
                    DayCountView(calculator: calculator)
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .background(Color.swBackground)
                .navigationTitle("SOTKA")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

#Preview {
    HomeScreen()
        .environment(StatusManager())
}
