//
//  ExchangeRateServiceProtocol.swift
//  CurrencyExchanger
//
//  Created by KarLG on 5/28/26.
//

import Foundation

protocol ExchangeRateServiceProtocol: Sendable {
    func fetchRates(baseCurrency: String) async throws -> ExchangeRatesResponse
}

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse(statusCode: Int)
    case decodingFailed(underlying: Error)
    case noInternet

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is malformed."
        case .invalidResponse(let code):
            return "Server returned an unexpected response (HTTP \(code))."
        case .decodingFailed(let error):
            return "Failed to parse server data: \(error.localizedDescription)"
        case .noInternet:
            return "No internet connection. Please check your network."
        }
    }
}
