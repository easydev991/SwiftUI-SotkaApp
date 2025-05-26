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
    private let currentDayTitle = NSLocalizedString("Current day", comment: "")
    private let daysLeftTitle = NSLocalizedString("Days left", comment: "")
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if let calculator = DayCalculator(statusManager.currentDay) {
                    // В старом приложении это HomeCountCell
                    HStack(spacing: 12) {
                        makeDayStack(title: currentDayTitle, day: calculator.currentDay)
                        makeDayStack(title: daysLeftTitle, day: calculator.daysLeft)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.swBackground)
            .navigationTitle("SOTKA")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private extension HomeScreen {
    func makeDayStack(title: String, day: Int) -> some View {
        VStack(spacing: 4) {
            Text(title)
            Text("\(day)")
                .contentTransition(.numericText())
                .font(.title.bold())
        }
    }
}

#Preview {
    HomeScreen()
        .environment(StatusManager())
}
