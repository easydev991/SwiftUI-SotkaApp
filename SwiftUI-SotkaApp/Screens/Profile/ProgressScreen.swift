//
//  ProgressScreen.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 25.05.2025.
//

import SwiftUI

struct ProgressScreen: View {
    let user: User
    
    var body: some View {
        Text("Progress")
            .navigationTitle("Progress")
    }
}

#Preview {
    ProgressScreen(user: .init(from: .preview))
}
