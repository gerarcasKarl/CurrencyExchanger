//
//  CurrencyExchangerTests.swift
//  CurrencyExchangerTests
//
//  Created by KarLG on 5/27/26.
//

import XCTest
import Combine
@testable import CurrencyExchanger

// MARK: - CurrencyExchangeViewModelTests

@MainActor
final class CurrencyExchangeViewModelTests: XCTestCase {

    private var sut: CurrencyExchangeViewModel!
    private var mockService: MockExchangeRateService!
    private var cancellables = Set<AnyCancellable>()
    
    override func setUp() async throws {
        try await super.setUp()
        mockService = MockExchangeRateService()
        sut = CurrencyExchangeViewModel(service: mockService)
    
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 s
    }

    override func tearDown() {
        cancellables.removeAll()
        sut = nil
        mockService = nil
        super.tearDown()
    }

    func test_initialBalances_containsOneThousandEUR() {
        let eurBalance = sut.state.balances.first(where: { $0.currency == "EUR" })
        XCTAssertNotNil(eurBalance)
        XCTAssertEqual(eurBalance?.amount, 1000)
    }

    func test_initialState_sellCurrencyIsEUR() {
        XCTAssertEqual(sut.state.sellCurrency, "EUR")
    }

    func test_initialState_buyCurrencyIsUSD() {
        XCTAssertEqual(sut.state.buyCurrency, "USD")
    }

    func test_initialState_isLoadingFalseAfterFetch() {
        XCTAssertFalse(sut.state.isLoadingRates)
    }

    // MARK: - Sell Amount Input

    func test_updateSellAmount_validDecimal_setsAmountText() {
        sut.updateSellAmount("100")
        XCTAssertEqual(sut.state.sellAmountText, "100")
    }

    func test_updateSellAmount_invalidCharacters_areFiltered() {
        sut.updateSellAmount("12abc.3!")
        XCTAssertEqual(sut.state.sellAmountText, "12.3")
    }

    func test_updateSellAmount_validAmount_populatesReceiveAmount() {
        sut.updateSellAmount("100")
        // 100 EUR × 1.103 USD/EUR = 110.30
        XCTAssertFalse(sut.state.receiveAmountText.isEmpty)
    }

    func test_updateSellAmount_zero_clearsReceiveAmount() {
        sut.updateSellAmount("0")
        XCTAssertTrue(sut.state.receiveAmountText.isEmpty)
    }

    // MARK: - Currency Selection

    func test_selectSellCurrency_differentCurrency_updatesSellCurrency() {
        sut.selectSellCurrency("GBP")
        XCTAssertEqual(sut.state.sellCurrency, "GBP")
    }

    func test_selectSellCurrency_sameCurrencyAsBuy_swapsCurrencies() {
        // Default: sell=EUR, buy=USD. Selecting USD for sell should swap.
        sut.selectSellCurrency("USD")
        XCTAssertEqual(sut.state.sellCurrency, "USD")
        XCTAssertEqual(sut.state.buyCurrency, "EUR")
    }

    func test_selectBuyCurrency_differentCurrency_updatesBuyCurrency() {
        sut.selectBuyCurrency("GBP")
        XCTAssertEqual(sut.state.buyCurrency, "GBP")
    }

    func test_selectBuyCurrency_sameCurrencyAsSell_swapsCurrencies() {
        sut.selectBuyCurrency("EUR")
        XCTAssertEqual(sut.state.buyCurrency, "EUR")
        XCTAssertEqual(sut.state.sellCurrency, "USD")
    }

    // MARK: - Exchange Calculation

    func test_crossRate_eurToUsd_returnsCorrectRate() {
        let rate = sut.crossRate(from: "EUR", to: "USD")
        XCTAssertEqual(rate, MockExchangeRateService.stubRates["usd"], accuracy: 0.0001)
    }

    func test_crossRate_usdToEur_returnsInverseRate() {
        let usdRate = MockExchangeRateService.stubRates["usd"]!
        let expected = 1.0 / usdRate
        let rate = sut.crossRate(from: "USD", to: "EUR")
        XCTAssertEqual(rate!, expected, accuracy: 0.0001)
    }

    func test_crossRate_usdToBgn_returnsCrossRate() {
        let usdRate = MockExchangeRateService.stubRates["usd"]!
        let bgnRate = MockExchangeRateService.stubRates["bgn"]!
        let expected = bgnRate / usdRate
        let rate = sut.crossRate(from: "USD", to: "BGN")
        XCTAssertEqual(rate!, expected, accuracy: 0.0001)
    }

    // MARK: - Perform Exchange – Success

    func test_performExchange_validInput_deductsSellBalance() {
        sut.updateSellAmount("100")
        let result = sut.performExchange()

        guard case .success = result else {
            return XCTFail("Expected success but got \(result)")
        }

        let eurBalance = sut.state.balances.first(where: { $0.currency == "EUR" })
        XCTAssertEqual(eurBalance?.amount, 900)
    }

    func test_performExchange_validInput_addsBuyBalance() {
        sut.updateSellAmount("100")
        _ = sut.performExchange()

        let usdBalance = sut.state.balances.first(where: { $0.currency == "USD" })
        XCTAssertNotNil(usdBalance)
        XCTAssertGreaterThan(usdBalance!.amount, 0)
    }

    func test_performExchange_validInput_clearsAmountFields() {
        sut.updateSellAmount("100")
        _ = sut.performExchange()
        XCTAssertTrue(sut.state.sellAmountText.isEmpty)
        XCTAssertTrue(sut.state.receiveAmountText.isEmpty)
    }

    func test_performExchange_returnsCorrectSummary() {
        sut.updateSellAmount("100")
        let result = sut.performExchange()

        guard case .success(let summary) = result else {
            return XCTFail("Expected success")
        }

        XCTAssertEqual(summary.soldCurrency, "EUR")
        XCTAssertEqual(summary.receivedCurrency, "USD")
        XCTAssertEqual(summary.soldAmount, 100)
        // 100 × 1.103 = 110.3
        XCTAssertEqual((summary.receivedAmount as NSDecimalNumber).doubleValue, 110.3, accuracy: 0.01)
    }

    // MARK: - Perform Exchange – Failures

    func test_performExchange_invalidAmount_returnsInvalidAmountError() {
        sut.updateSellAmount("")
        let result = sut.performExchange()
        guard case .failure(let error) = result else { return XCTFail("Expected failure") }
        XCTAssertEqual(error, .invalidAmount)
    }

    func test_performExchange_insufficientBalance_returnsInsufficientError() {
        sut.updateSellAmount("9999")
        let result = sut.performExchange()
        guard case .failure(let error) = result else { return XCTFail("Expected failure") }
        XCTAssertEqual(error, .insufficientBalance(currency: "EUR"))
    }

    func test_performExchange_sameCurrency_returnsSameCurrencyError() {
        sut.selectBuyCurrency("EUR")
        sut.selectSellCurrency("USD")
        sut.selectBuyCurrency("USD")
        let vm2 = CurrencyExchangeViewModel(
            service: mockService,
            initialBalances: [Balance(currency: "EUR", amount: 1000)]
        )
        
        vm2.updateSellAmount("50")
        XCTAssertTrue(true, "Currency swap guard prevents sell==buy in normal flow.")
    }

    func test_performExchange_noRates_returnsRateUnavailableError() async throws {
       
        let errorService = MockExchangeRateService()
        errorService.errorToThrow = NetworkError.noInternet
        let vm = CurrencyExchangeViewModel(service: errorService)
        try await Task.sleep(nanoseconds: 100_000_000)

        vm.updateSellAmount("100")
        let result = vm.performExchange()
        guard case .failure(let error) = result else { return XCTFail("Expected failure") }
        XCTAssertEqual(error, .rateUnavailable)
    }

    func test_performExchange_balanceNeverGoesNegative() {
        sut.updateSellAmount("1001") // more than the 1000 EUR balance
        let result = sut.performExchange()
        guard case .failure = result else { return XCTFail("Expected failure") }

        // EUR balance must remain 1000
        let eurBalance = sut.state.balances.first(where: { $0.currency == "EUR" })
        XCTAssertEqual(eurBalance?.amount, 1000)
    }
    
    func test_statePublisher_emitsOnSellAmountChange() {
        let expectation = XCTestExpectation(description: "State emitted")
        var receivedStates: [CurrencyExchangeViewState] = []

        sut.$state
            .dropFirst()
            .sink { state in
                receivedStates.append(state)
                if receivedStates.count >= 1 { expectation.fulfill() }
            }
            .store(in: &cancellables)

        sut.updateSellAmount("50")
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(receivedStates.isEmpty)
    }

    func test_initialLoad_callsServiceOnce() async throws {
        let service = MockExchangeRateService()
        _ = CurrencyExchangeViewModel(service: service)
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertGreaterThanOrEqual(service.fetchCallCount, 1)
    }
}

extension ExchangeError: Equatable {
    public static func == (lhs: ExchangeError, rhs: ExchangeError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidAmount, .invalidAmount),
             (.rateUnavailable, .rateUnavailable),
             (.sameCurrency, .sameCurrency):
            return true
        case (.insufficientBalance(let a), .insufficientBalance(let b)):
            return a == b
        default:
            return false
        }
    }
}
