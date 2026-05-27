//
//  MockExchangeRateService.swift
//  CurrencyExchangerTests
//
//  Created by KarLG on 5/28/26.
//

@testable import CurrencyExchanger
import Foundation

// MARK: - MockExchangeRateService

final class MockExchangeRateService: ExchangeRateServiceProtocol, @unchecked Sendable {
    
    var errorToThrow: Error?

    var responseToReturn: ExchangeRatesResponse?

    private(set) var fetchCallCount = 0

    func fetchRates(baseCurrency: String) async throws -> ExchangeRatesResponse {
        fetchCallCount += 1
        if let error = errorToThrow { throw error }
        return responseToReturn ?? Self.stubResponse
    }

    static let stubRates: [String: Double] = [
        "usd": 1.103,
        "bgn": 1.956,
        "gbp": 0.856,
        "jpy": 162.4,
        "chf": 0.974,
        "cad": 1.501,
        "aud": 1.652,
        "czk": 25.12,
        "pln": 4.298
    ]

    static let stubResponse = ExchangeRatesResponse(
        date: "2024-01-01",
        baseCurrency: "eur",
        rates: stubRates
    )
}
