//
//  HomeScreen.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 11.05.2025.
//

import SwiftUI

struct HomeScreen: View {
    var body: some View {
        NavigationStack {
            Text("Home")
                .navigationTitle("Home")
            #if DEBUG
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink(destination: DemoSwiftDataScreen()) {
                            Text("Demo SwiftData")
                        }
                    }
                }
            #endif
        }
    }
}

#if DEBUG
#Preview {
    HomeScreen()
}
#endif
