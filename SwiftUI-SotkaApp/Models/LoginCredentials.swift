//
//  LoginCredentials.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 15.05.2025.
//

import Foundation
import SWUtils

struct LoginCredentials: Equatable {
    var login: String
    var password: String
    let minPasswordSize: Int

    init(
        login: String = "",
        password: String = "",
        minPasswordSize: Int = 6
    ) {
        self.login = login
        self.password = password
        self.minPasswordSize = minPasswordSize
    }

    var isReady: Bool {
        !login.isEmpty && password.trueCount >= minPasswordSize
    }

    var canRestorePassword: Bool { !login.isEmpty }

    func canLogIn(isError: Bool) -> Bool {
        isReady && !isError
    }
}
