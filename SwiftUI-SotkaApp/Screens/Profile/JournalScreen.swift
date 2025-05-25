//
//  JournalScreen.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 25.05.2025.
//

import SwiftUI

struct JournalScreen: View {
    let user: User
    
    var body: some View {
        Text("Journal")
            .navigationTitle("Journal")
    }
}

#Preview {
    JournalScreen(user: .init(from: .preview))
}
