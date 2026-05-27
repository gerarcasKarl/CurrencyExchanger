//
//  Balance.swift
//  CurrencyExchanger
//
//  Created by KarLG on 5/27/26.
//

import Foundation

struct Balance: Equatable, Sendable, Identifiable {
    let id: String   // currency code used as stable identifier
    let currency: String
    var amount: Decimal

    init(currency: String, amount: Decimal) {
        self.id = currency
        self.currency = currency
        self.amount = amount
    }

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.usesGroupingSeparator = true
        return formatter.string(from: amount as NSDecimalNumber) ?? "0.00"
    }
}
