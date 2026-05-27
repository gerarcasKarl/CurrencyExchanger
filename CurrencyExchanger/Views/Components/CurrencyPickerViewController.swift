//
//  CurrencyPickerViewController.swift
//  CurrencyExchanger
//
//  Created by KarLG on 5/28/26.
//

import Foundation
import UIKit

protocol CurrencyPickerViewControllerDelegate: AnyObject {
    func currencyPicker(_ picker: CurrencyPickerViewController, didSelect currency: String)
}

final class CurrencyPickerViewController: UIViewController {
    
    weak var delegate: CurrencyPickerViewControllerDelegate?
    private let currencies: [String]
    private let selectedCurrency: String
    private let title_: String
    
    private let handleView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.systemGray3
        v.layer.cornerRadius = 2.5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let headerLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.dataSource = self
        tv.delegate = self
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tv.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        return tv
    }()
    
    init(currencies: [String], selected: String, pickerTitle: String) {
        self.currencies = currencies
        self.selectedCurrency = selected
        self.title_ = pickerTitle
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        if let idx = currencies.firstIndex(of: selectedCurrency) {
            let ip = IndexPath(row: idx, section: 0)
            tableView.scrollToRow(at: ip, at: .middle, animated: false)
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.masksToBounds = true
        
        headerLabel.text = title_
        
        view.addSubview(handleView)
        view.addSubview(headerLabel)
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            handleView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            handleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            handleView.widthAnchor.constraint(equalToConstant: 40),
            handleView.heightAnchor.constraint(equalToConstant: 5),
            
            headerLabel.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: 16),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            tableView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension CurrencyPickerViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        currencies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let currency = currencies[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = currency
        config.textProperties.font = .systemFont(ofSize: 16)
        cell.contentConfiguration = config
        cell.accessoryType = currency == selectedCurrency ? .checkmark : .none
        cell.tintColor = .appBlue
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let currency = currencies[indexPath.row]
        delegate?.currencyPicker(self, didSelect: currency)
        dismiss(animated: true)
    }
}
