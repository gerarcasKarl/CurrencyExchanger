//
//  ExchangeRateService.swift
//  CurrencyExchanger
//
//  Created by KarLG on 5/28/26.
//

import Foundation

final class ExchangeRateService: ExchangeRateServiceProtocol {

    // MARK: - Constants

    private enum API {
        static let baseURL = "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1"
        static func ratesURL(for currency: String) -> String {
            "\(baseURL)/currencies/\(currency.lowercased()).json"
        }
    }

    // MARK: - Dependencies

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - ExchangeRateServiceProtocol
    
    func fetchRates(baseCurrency: String) async throws -> ExchangeRatesResponse {
        let urlString = API.ratesURL(for: baseCurrency)
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(from: url)
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet {
            throw NetworkError.noInternet
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse(statusCode: -1)
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse(statusCode: httpResponse.statusCode)
        }
        
        do {
            let decoded = try JSONDecoder().decode(ExchangeRatesResponse.self, from: data)
            return decoded
        } catch {
            throw NetworkError.decodingFailed(underlying: error)
        }
    }
}
