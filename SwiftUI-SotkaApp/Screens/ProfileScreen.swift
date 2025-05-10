//
//  ProfileScreen.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 10.05.2025.
//

import SwiftUI

struct ProfileScreen: View {
    var body: some View {
        NavigationStack {
            Text("Profile")
                .navigationTitle("Profile")
        }
    }
}

#if DEBUG
#Preview {
    ProfileScreen()
}
#endif
