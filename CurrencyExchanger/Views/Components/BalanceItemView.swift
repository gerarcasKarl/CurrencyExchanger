//
//  BalanceItemView.swift
//  CurrencyExchanger
//
//  Created by KarLG on 5/28/26.
//

import Foundation
import UIKit

final class BalanceItemView: UIView {

    private let amountLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(amountLabel)
        NSLayoutConstraint.activate([
            amountLabel.topAnchor.constraint(equalTo: topAnchor),
            amountLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            amountLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            amountLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with balance: Balance) {
        amountLabel.text = "\(balance.formattedAmount) \(balance.currency)"
    }
}
