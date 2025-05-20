//
//  PreviewModelContainer.swift
//  SwiftUI-Days
//
//  Created by Oleg991 on 24.03.2024.
//

#if DEBUG
import SwiftData

enum PreviewModelContainer {
    @MainActor
    static func make(with user: User) -> ModelContainer {
        let container = try! ModelContainer(
            for: User.self,
            configurations: .init(isStoredInMemoryOnly: true)
        )
        container.mainContext.insert(user)
        return container
    }
}
#endif
