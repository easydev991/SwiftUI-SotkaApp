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
            ScrollView {
                Text("Start date: \(statusManager.startDate)")
            }
            .frame(maxWidth: .infinity)
            .background(Color.swBackground)
            .navigationTitle("Home")
        }
    }
}

#if DEBUG
#Preview {
    HomeScreen()
        .environment(StatusManager())
}
#endif
