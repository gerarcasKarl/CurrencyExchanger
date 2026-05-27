//
//  CurrencyExchangeViewController.swift
//  CurrencyExchanger
//
//  Created by KarLG on 5/28/26.
//

import Foundation
import UIKit
import Combine

@MainActor
final class CurrencyExchangeViewController: UIViewController {
    
    private let viewModel: CurrencyExchangeViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI: Scroll container

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.alwaysBounceVertical = true
        sv.keyboardDismissMode = .onDrag
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private lazy var contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - UI: Balances section

    private lazy var balancesSectionLabel = makeSectionLabel("MY BALANCES")

    private lazy var balancesScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private lazy var balancesStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 28
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // MARK: - UI: Exchange section

    private lazy var exchangeSectionLabel = makeSectionLabel("CURRENCY EXCHANGE")

    private lazy var exchangeCard: UIView = {
        let v = UIView()
        v.backgroundColor = .cardBackground
        v.layer.cornerRadius = 16
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowRadius = 10
        v.layer.shadowOffset = CGSize(width: 0, height: 3)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var sellIconView  = makeDirectionIcon(isUp: true)
    private lazy var sellLabel     = makeRowLabel("Sell")
    private lazy var sellTextField = makeSellTextField()
    private lazy var sellCurrencyButton   = makeCurrencyButton()

    private lazy var separatorView: UIView = {
        let v = UIView()
        v.backgroundColor = .separator
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var receiveIconView      = makeDirectionIcon(isUp: false)
    private lazy var receiveLabel         = makeRowLabel("Receive")
    private lazy var receiveAmountLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .regular)
        l.textColor = .systemGreen
        l.textAlignment = .right
        l.text = ""
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private lazy var receiveCurrencyButton = makeCurrencyButton()

    private lazy var rateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.hidesWhenStopped = true
        ai.color = .appBlue
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    private lazy var errorLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = .systemRed
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var lastUpdatedLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .regular)
        l.textColor = .tertiaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()


    private lazy var submitButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .appBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0)
        config.attributedTitle = AttributedString(
            "SUBMIT",
            attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 16, weight: .bold)
            ])
        )
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        return b
    }()

    init(viewModel: CurrencyExchangeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupHierarchy()
        setupConstraints()
        setupActions()
        bindViewModel()
    }

    private func setupNavigationBar() {
        title = "Currency converter"
        view.backgroundColor = .systemGroupedBackground

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .appBlue
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navigationController?.navigationBar.standardAppearance   = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance    = appearance
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.isTranslucent = false

        let refreshSpinner = UIActivityIndicatorView(style: .medium)
        refreshSpinner.color = .white
        refreshSpinner.tag = 99
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: refreshSpinner)
    }

    private func setupHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(balancesSectionLabel)
        contentView.addSubview(balancesScrollView)
        balancesScrollView.addSubview(balancesStackView)

        contentView.addSubview(exchangeSectionLabel)
        contentView.addSubview(exchangeCard)

        exchangeCard.addSubview(sellIconView)
        exchangeCard.addSubview(sellLabel)
        exchangeCard.addSubview(sellTextField)
        exchangeCard.addSubview(sellCurrencyButton)
        exchangeCard.addSubview(separatorView)
        exchangeCard.addSubview(receiveIconView)
        exchangeCard.addSubview(receiveLabel)
        exchangeCard.addSubview(receiveAmountLabel)
        exchangeCard.addSubview(receiveCurrencyButton)

        contentView.addSubview(rateLabel)
        contentView.addSubview(loadingIndicator)
        contentView.addSubview(errorLabel)
        contentView.addSubview(lastUpdatedLabel)

        contentView.addSubview(submitButton)
    }

    private func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide
        let iconSize: CGFloat = 40
        let rowH: CGFloat = 64
        let padding: CGFloat = 20

        NSLayoutConstraint.activate([

            scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            balancesSectionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            balancesSectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            balancesSectionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            balancesScrollView.topAnchor.constraint(equalTo: balancesSectionLabel.bottomAnchor, constant: 12),
            balancesScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            balancesScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            balancesScrollView.heightAnchor.constraint(equalToConstant: 32),

            balancesStackView.topAnchor.constraint(equalTo: balancesScrollView.topAnchor),
            balancesStackView.leadingAnchor.constraint(equalTo: balancesScrollView.leadingAnchor, constant: padding),
            balancesStackView.trailingAnchor.constraint(equalTo: balancesScrollView.trailingAnchor, constant: -padding),
            balancesStackView.bottomAnchor.constraint(equalTo: balancesScrollView.bottomAnchor),
            balancesStackView.heightAnchor.constraint(equalTo: balancesScrollView.heightAnchor),

            exchangeSectionLabel.topAnchor.constraint(equalTo: balancesScrollView.bottomAnchor, constant: 28),
            exchangeSectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            exchangeSectionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            exchangeCard.topAnchor.constraint(equalTo: exchangeSectionLabel.bottomAnchor, constant: 12),
            exchangeCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            exchangeCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            sellIconView.topAnchor.constraint(equalTo: exchangeCard.topAnchor, constant: 12),
            sellIconView.leadingAnchor.constraint(equalTo: exchangeCard.leadingAnchor, constant: 16),
            sellIconView.widthAnchor.constraint(equalToConstant: iconSize),
            sellIconView.heightAnchor.constraint(equalToConstant: iconSize),

            sellLabel.centerYAnchor.constraint(equalTo: sellIconView.centerYAnchor),
            sellLabel.leadingAnchor.constraint(equalTo: sellIconView.trailingAnchor, constant: 14),
            sellLabel.widthAnchor.constraint(equalToConstant: 54),

            sellCurrencyButton.centerYAnchor.constraint(equalTo: sellIconView.centerYAnchor),
            sellCurrencyButton.trailingAnchor.constraint(equalTo: exchangeCard.trailingAnchor, constant: -16),

            sellTextField.centerYAnchor.constraint(equalTo: sellIconView.centerYAnchor),
            sellTextField.leadingAnchor.constraint(equalTo: sellLabel.trailingAnchor, constant: 8),
            sellTextField.trailingAnchor.constraint(equalTo: sellCurrencyButton.leadingAnchor, constant: -8),

            separatorView.topAnchor.constraint(equalTo: sellIconView.bottomAnchor, constant: 12),
            separatorView.leadingAnchor.constraint(equalTo: exchangeCard.leadingAnchor, constant: 70),
            separatorView.trailingAnchor.constraint(equalTo: exchangeCard.trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),

            receiveIconView.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 12),
            receiveIconView.leadingAnchor.constraint(equalTo: exchangeCard.leadingAnchor, constant: 16),
            receiveIconView.widthAnchor.constraint(equalToConstant: iconSize),
            receiveIconView.heightAnchor.constraint(equalToConstant: iconSize),
            receiveIconView.bottomAnchor.constraint(equalTo: exchangeCard.bottomAnchor, constant: -12),

            receiveLabel.centerYAnchor.constraint(equalTo: receiveIconView.centerYAnchor),
            receiveLabel.leadingAnchor.constraint(equalTo: receiveIconView.trailingAnchor, constant: 14),
            receiveLabel.widthAnchor.constraint(equalToConstant: 54),

            receiveCurrencyButton.centerYAnchor.constraint(equalTo: receiveIconView.centerYAnchor),
            receiveCurrencyButton.trailingAnchor.constraint(equalTo: exchangeCard.trailingAnchor, constant: -16),

            receiveAmountLabel.centerYAnchor.constraint(equalTo: receiveIconView.centerYAnchor),
            receiveAmountLabel.leadingAnchor.constraint(equalTo: receiveLabel.trailingAnchor, constant: 8),
            receiveAmountLabel.trailingAnchor.constraint(equalTo: receiveCurrencyButton.leadingAnchor, constant: -8),

            rateLabel.topAnchor.constraint(equalTo: exchangeCard.bottomAnchor, constant: 12),
            rateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            rateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            loadingIndicator.topAnchor.constraint(equalTo: rateLabel.bottomAnchor, constant: 6),
            loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            errorLabel.topAnchor.constraint(equalTo: rateLabel.bottomAnchor, constant: 6),
            errorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            errorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            lastUpdatedLabel.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 2),
            lastUpdatedLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            lastUpdatedLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            submitButton.topAnchor.constraint(equalTo: lastUpdatedLabel.bottomAnchor, constant: 32),
            submitButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            submitButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            submitButton.heightAnchor.constraint(equalToConstant: 54),
            submitButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }

    private func setupActions() {
        sellTextField.addTarget(self, action: #selector(sellAmountChanged(_:)), for: .editingChanged)
        sellCurrencyButton.addTarget(self, action: #selector(sellCurrencyTapped), for: .touchUpInside)
        receiveCurrencyButton.addTarget(self, action: #selector(receiveCurrencyTapped), for: .touchUpInside)
    }
    
    private func bindViewModel() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.applyState(state)
            }
            .store(in: &cancellables)
    }

    private func applyState(_ state: CurrencyExchangeViewState) {
        updateBalancesStrip(state.balances)

        sellCurrencyButton.configuration?.attributedTitle = currencyButtonTitle(state.sellCurrency)
        if !sellTextField.isEditing {
            sellTextField.text = state.sellAmountText.isEmpty ? "" : state.sellAmountText
        }

        receiveCurrencyButton.configuration?.attributedTitle = currencyButtonTitle(state.buyCurrency)
        receiveAmountLabel.text = state.receiveAmountText.isEmpty ? "" : "+\(state.receiveAmountText)"

        rateLabel.text = state.exchangeRateText ?? ""

        if state.isLoadingRates {
            loadingIndicator.startAnimating()
            navSpinner?.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
            navSpinner?.stopAnimating()
        }

        errorLabel.isHidden = state.ratesError == nil
        errorLabel.text = state.ratesError

        lastUpdatedLabel.text = state.lastUpdatedText ?? ""

        submitButton.isEnabled = state.canSubmit
        submitButton.alpha = state.canSubmit ? 1.0 : 0.5
    }

    private var navSpinner: UIActivityIndicatorView? {
        (navigationItem.rightBarButtonItem?.customView as? UIActivityIndicatorView)
    }

    private func updateBalancesStrip(_ balances: [Balance]) {
        let existingCurrencies = balancesStackView.arrangedSubviews
            .compactMap { ($0 as? BalanceItemView) }
            .map { $0.accessibilityIdentifier ?? "" }

        let newCurrencies = balances.map { $0.currency }
        if existingCurrencies != newCurrencies {
            balancesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            balances.forEach { balance in
                let item = BalanceItemView()
                item.accessibilityIdentifier = balance.currency
                item.configure(with: balance)
                balancesStackView.addArrangedSubview(item)
            }
        } else {
            zip(balancesStackView.arrangedSubviews, balances).forEach { view, balance in
                (view as? BalanceItemView)?.configure(with: balance)
            }
        }
    }

    // MARK: - Button actions

    @objc private func sellAmountChanged(_ tf: UITextField) {
        viewModel.updateSellAmount(tf.text ?? "")
    }

    @objc private func sellCurrencyTapped() {
        presentCurrencyPicker(selectedCurrency: viewModel.state.sellCurrency, isSell: true)
    }

    @objc private func receiveCurrencyTapped() {
        presentCurrencyPicker(selectedCurrency: viewModel.state.buyCurrency, isSell: false)
    }

    @objc private func submitTapped() {
        view.endEditing(true)
        let result = viewModel.performExchange()
        switch result {
        case .success(let summary):
            presentSuccessAlert(message: summary.message)
        case .failure(let error):
            presentErrorAlert(message: error.errorDescription ?? "An error occurred.")
        }
    }

    // MARK: - Currency picker

    private func presentCurrencyPicker(selectedCurrency: String, isSell: Bool) {
        let picker = CurrencyPickerViewController(
            currencies: viewModel.state.availableCurrencies,
            selected: selectedCurrency,
            pickerTitle: isSell ? "Select sell currency" : "Select receive currency"
        )
        picker.delegate = self
        picker.view.tag = isSell ? 0 : 1 // 0 = sell, 1 = buy

        if let sheet = picker.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        present(picker, animated: true)
    }

    // MARK: - Alerts

    private func presentSuccessAlert(message: String) {
        let alert = UIAlertController(title: "Currency Converted!", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Done", style: .default))
        present(alert, animated: true)
    }

    private func presentErrorAlert(message: String) {
        let alert = UIAlertController(title: "Conversion Failed", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }
}

extension CurrencyExchangeViewController: CurrencyPickerViewControllerDelegate {
    func currencyPicker(_ picker: CurrencyPickerViewController, didSelect currency: String) {
        if picker.view.tag == 0 {
            viewModel.selectSellCurrency(currency)
        } else {
            viewModel.selectBuyCurrency(currency)
        }
    }
}

private extension CurrencyExchangeViewController {

    func makeSectionLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textColor = .secondaryLabel
        l.letterSpacing(1.2)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    func makeDirectionIcon(isUp: Bool) -> UIView {
        let container = UIView()
        container.backgroundColor = isUp ? .sellRed : .buyGreen
        container.layer.cornerRadius = 20
        container.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView()
        let symbolName = isUp ? "arrow.up" : "arrow.down"
        imageView.image = UIImage(systemName: symbolName, withConfiguration:
            UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold))
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    func makeRowLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 17, weight: .regular)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    func makeSellTextField() -> UITextField {
        let tf = UITextField()
        tf.placeholder = "0"
        tf.font = .systemFont(ofSize: 17, weight: .regular)
        tf.keyboardType = .decimalPad
        tf.textAlignment = .right
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }

    func makeCurrencyButton() -> UIButton {
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = .label
        config.imagePlacement = .trailing
        config.imagePadding = 4
        config.image = UIImage(systemName: "chevron.down",
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .medium))
        config.attributedTitle = currencyButtonTitle("---")
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }

    func currencyButtonTitle(_ code: String) -> AttributedString {
        AttributedString(
            code,
            attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
                .foregroundColor: UIColor.label
            ])
        )
    }
}

private extension UILabel {
    func letterSpacing(_ spacing: CGFloat) {
        guard let text = text else { return }
        let attributed = NSMutableAttributedString(string: text)
        attributed.addAttribute(.kern, value: spacing, range: NSRange(location: 0, length: text.count))
        attributedText = attributed
    }
}
