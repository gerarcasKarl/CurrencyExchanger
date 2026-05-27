//
//  ExchangeResult.swift
//  CurrencyExchanger
//
//  Created by KarLG on 5/28/26.
//

import Foundation

enum ExchangeResult: Sendable {
    case success(ExchangeSummary)
    case failure(ExchangeError)
}

struct ExchangeSummary: Sendable {
    let soldAmount: Decimal
    let soldCurrency: String
    let receivedAmount: Decimal
    let receivedCurrency: String

    var message: String {
        let sold = formatDecimal(soldAmount)
        let received = formatDecimal(receivedAmount)
        return "You have exchanged \(sold) \(soldCurrency) to \(received) \(receivedCurrency)"
    }

    private func formatDecimal(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        return formatter.string(from: value as NSDecimalNumber) ?? "0.00"
    }
}

enum ExchangeError: LocalizedError, Sendable {
    case invalidAmount
    case rateUnavailable
    case insufficientBalance(currency: String)
    case sameCurrency

    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Please enter a valid amount greater than zero."
        case .rateUnavailable:
            return "Exchange rate is currently unavailable. Please try again shortly."
        case .insufficientBalance(let currency):
            return "Insufficient balance in \(currency)."
        case .sameCurrency:
            return "Sell and receive currencies must be different."
        }
    }
}
