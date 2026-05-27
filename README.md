# CurrencyExchanger

A native iOS application for real-time currency exchange built with **UIKit** (programmatic, no Storyboards), **Swift 6**, **MVVM**, and **Combine**.

---

## Screenshots

> The UI mirrors the reference design: a blue navigation bar, a horizontally scrollable balances strip, and a card-based exchange form with sell/receive rows and a submit button.

---

## Features

| Feature | Detail |
|---|---|
| Multi-currency balances | Initial 1 000 EUR; new currencies auto-created on first buy |
| Live exchange rates | [fawazahmed0 Currency API](https://github.com/fawazahmed0/exchange-api) |
| Auto-refresh | Every **5 seconds** via async/await + `Task.sleep` |
| Cross rates | Any pair calculated via EUR pivot |
| Validation | Amount > 0, rate available, no negative balance, same-currency swap guard |
| Error handling | Network errors surfaced gracefully; stale rates kept on subsequent failures |
| Unit tests | ViewModel fully tested with a mock service |

---

## Architecture

```
┌────────────────────────────────────────────────────┐
│                  SceneDelegate (DI root)            │
│  ExchangeRateService ──► CurrencyExchangeViewModel  │
│                               │ @Published state    │
│                    CurrencyExchangeViewController   │
│                     (UIKit + Combine bindings)      │
└────────────────────────────────────────────────────┘
```

### Layers

**Models** (`Balance`, `ExchangeRatesResponse`, `ExchangeResult`)
- Plain `Sendable` structs – no framework dependencies.

**Services** (`ExchangeRateServiceProtocol` + `ExchangeRateService`)
- Protocol-first: swap the live service for a mock in tests or previews with zero changes to the ViewModel.

**ViewModel** (`CurrencyExchangeViewModel`)
- `@MainActor final class` – all mutations run on the main actor; safe to bind directly to UIKit.
- Single `@Published var state: CurrencyExchangeViewState` – one source of truth.
- `Task`-based auto-refresh loop replaces `Timer`, plays nicely with Swift 6 strict concurrency.

**Views** (`CurrencyExchangeViewController`, `CurrencyPickerViewController`, `BalanceItemView`)
- Fully programmatic Auto Layout.
- Combine sink on `viewModel.$state` drives all UI updates.

---

## Project Structure

```
CurrencyExchanger/
├── App/
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift          ← Dependency injection root
│   └── Info.plist
├── Models/
│   ├── Balance.swift
│   ├── ExchangeRatesResponse.swift
│   └── ExchangeResult.swift
├── Services/
│   ├── ExchangeRateServiceProtocol.swift
│   └── ExchangeRateService.swift
├── ViewModels/
│   └── CurrencyExchangeViewModel.swift
├── Views/
│   ├── CurrencyExchangeViewController.swift
│   └── Components/
│       ├── BalanceItemView.swift
│       └── CurrencyPickerViewController.swift
└── Extensions/
    ├── UIColor+Theme.swift
    └── UIView+Helpers.swift

CurrencyExchangerTests/
├── Mocks/
│   └── MockExchangeRateService.swift
└── CurrencyExchangeViewModelTests.swift
