//
//  CurrencyExchangeViewModel.swift
//  CurrencyExchanger
//
//  Created by KarLG on 5/28/26.
//

import Foundation
import Combine

struct CurrencyExchangeViewState {
    var balances: [Balance]
    var sellCurrency: String
    var buyCurrency: String
    var sellAmountText: String
    var receiveAmountText: String
    var exchangeRateText: String?
    var isLoadingRates: Bool
    var ratesError: String?
    var lastUpdatedText: String?
    var availableCurrencies: [String]

    var canSubmit: Bool {
        guard let amount = Decimal(string: sellAmountText), amount > 0 else { return false }
        return !isLoadingRates && ratesError == nil && sellCurrency != buyCurrency
    }
}


@MainActor
final class CurrencyExchangeViewModel: ObservableObject {
    @Published private(set) var state: CurrencyExchangeViewState

    private let service: ExchangeRateServiceProtocol
    private var rates: [String: Double] = [:]
    private var refreshTask: Task<Void, Never>?

    static let defaultCurrencies = ["EUR", "USD", "BGN", "GBP", "JPY", "CHF", "CAD", "AUD", "CZK", "PLN"]

    init(
        service: ExchangeRateServiceProtocol,
        initialBalances: [Balance] = [
            Balance(currency: "EUR", amount: 1000)
        ],
        supportedCurrencies: [String] = defaultCurrencies
    ) {
        self.service = service
        self.state = CurrencyExchangeViewState(
            balances: initialBalances,
            sellCurrency: initialBalances.first?.currency ?? "EUR",
            buyCurrency: supportedCurrencies.first(where: { $0 != initialBalances.first?.currency }) ?? "USD",
            sellAmountText: "",
            receiveAmountText: "",
            exchangeRateText: nil,
            isLoadingRates: true,
            ratesError: nil,
            lastUpdatedText: nil,
            availableCurrencies: supportedCurrencies
        )
        startAutoRefresh()
    }

    deinit {
        refreshTask?.cancel()
    }

    func updateSellAmount(_ text: String) {
        let filtered = text.filter { $0.isNumber || $0 == "." }
        state.sellAmountText = filtered
        recalculate()
    }

    func selectSellCurrency(_ currency: String) {
        guard currency != state.sellCurrency else { return }

        if currency == state.buyCurrency {
            state.buyCurrency = state.sellCurrency
        }
        state.sellCurrency = currency
        recalculate()
    }

    func selectBuyCurrency(_ currency: String) {
        guard currency != state.buyCurrency else { return }
        if currency == state.sellCurrency {
            state.sellCurrency = state.buyCurrency
        }
        state.buyCurrency = currency
        recalculate()
    }

    func performExchange() -> ExchangeResult {
        guard state.sellCurrency != state.buyCurrency else {
            return .failure(.sameCurrency)
        }
        guard let sellAmount = Decimal(string: state.sellAmountText), sellAmount > 0 else {
            return .failure(.invalidAmount)
        }
        guard let rate = crossRate(from: state.sellCurrency, to: state.buyCurrency) else {
            return .failure(.rateUnavailable)
        }

        let receiveAmount = sellAmount * Decimal(rate)

        guard let sellIdx = state.balances.firstIndex(where: { $0.currency == state.sellCurrency }) else {
            return .failure(.insufficientBalance(currency: state.sellCurrency))
        }
        guard state.balances[sellIdx].amount >= sellAmount else {
            return .failure(.insufficientBalance(currency: state.sellCurrency))
        }

        state.balances[sellIdx].amount -= sellAmount

        if let buyIdx = state.balances.firstIndex(where: { $0.currency == state.buyCurrency }) {
            state.balances[buyIdx].amount += receiveAmount
        } else {
            state.balances.append(Balance(currency: state.buyCurrency, amount: receiveAmount))
        }

        let summary = ExchangeSummary(
            soldAmount: sellAmount,
            soldCurrency: state.sellCurrency,
            receivedAmount: receiveAmount,
            receivedCurrency: state.buyCurrency
        )

        state.sellAmountText = ""
        state.receiveAmountText = ""
        state.exchangeRateText = nil

        return .success(summary)
    }

    private func startAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                await fetchRates()
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            }
        }
    }

    private func fetchRates() async {
        if rates.isEmpty { state.isLoadingRates = true }
        state.ratesError = nil

        do {
            let response = try await service.fetchRates(baseCurrency: "eur")
            rates = response.rates
            state.isLoadingRates = false
            state.lastUpdatedText = "Rates updated at \(shortTime(Date()))"
            recalculate()
        } catch {
            state.isLoadingRates = false
            if rates.isEmpty {
                state.ratesError = error.localizedDescription
            }
        }
    }

    private func recalculate() {
        guard
            let amount = Decimal(string: state.sellAmountText), amount > 0,
            let rate = crossRate(from: state.sellCurrency, to: state.buyCurrency)
        else {
            state.receiveAmountText = ""
            state.exchangeRateText = rateDescription()
            return
        }

        let result = amount * Decimal(rate)
        let nsResult = result as NSDecimalNumber
        state.receiveAmountText = String(format: "%.2f", nsResult.doubleValue)
        state.exchangeRateText = rateDescription()
    }

    func crossRate(from: String, to: String) -> Double? {
        let fromLC = from.lowercased()
        let toLC = to.lowercased()

        switch (fromLC, toLC) {
        case ("eur", _):
            return rates[toLC]
        case (_, "eur"):
            guard let fromRate = rates[fromLC], fromRate > 0 else { return nil }
            return 1.0 / fromRate
        default:
            guard let fromRate = rates[fromLC], fromRate > 0,
                  let toRate = rates[toLC] else { return nil }
            return toRate / fromRate
        }
    }

    private func rateDescription() -> String? {
        guard let rate = crossRate(from: state.sellCurrency, to: state.buyCurrency) else {
            return nil
        }
        return "1 \(state.sellCurrency) = \(String(format: "%.4f", rate)) \(state.buyCurrency)"
    }

    private func shortTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: date)
    }
}
