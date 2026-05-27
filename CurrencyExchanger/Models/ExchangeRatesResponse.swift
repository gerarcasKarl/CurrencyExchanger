//
//  ExchangeRatesResponse.swift
//  CurrencyExchanger
//
//  Created by KarLG on 5/27/26.
//

import Foundation

struct ExchangeRatesResponse: Sendable, Decodable {
    let date: String
    let baseCurrency: String
    let rates: [String: Double]
    
    nonisolated init(
        date: String,
        baseCurrency: String,
        rates: [String: Double]
    ) {
        self.date = date
        self.baseCurrency = baseCurrency
        self.rates = rates
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        
        let dateKey = DynamicCodingKey(stringValue: "date")
        date = (try? container.decode(String.self, forKey: dateKey)) ?? ""
        
        var decodedBase = ""
        var decodedRates: [String: Double] = [:]
        
        for key in container.allKeys where key.stringValue != "date" {
            decodedBase = key.stringValue
            decodedRates = (try? container.decode([String: Double].self, forKey: key)) ?? [:]
        }
        
        baseCurrency = decodedBase
        rates = decodedRates
    }
}

// MARK: - Dynamic CodingKey

struct DynamicCodingKey: CodingKey, Equatable {
    let stringValue: String
    var intValue: Int? { nil }

    init(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int)
    {
        return nil
    }
}
