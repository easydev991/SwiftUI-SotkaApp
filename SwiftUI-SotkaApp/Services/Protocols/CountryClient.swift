//
//  CountryClient.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 23.05.2025.
//

protocol CountryClient: Sendable {
    /// Загружает справочник стран/городов
    /// - Returns: Справочник стран/городов
    func getCountries() async throws -> [CountryResponse]
}
