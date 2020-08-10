//
//  ViewController.swift
//  CurrencyConverter
//
//  Created by Caroline Law on 8/8/20.
//  Copyright © 2020 CAL. All rights reserved.
//

import UIKit
import Combine

protocol CurrencyProtocolDelegate {
    func getFromCurrency(currency: String)
}

class ViewController: UIViewController, CurrencyProtocolDelegate {

    @IBOutlet var fromCurrencyTextField: UITextField!
    @IBOutlet var fromCurrencyButton: UIButton!
    @IBOutlet var toCurrencyCollectionView: UICollectionView!
    @IBOutlet var errorLabel: UILabel!

    var api = CurrencyAPI()
    var currencies = [String: String]()
    var currencyFullNames = [String]()
    var currencyAbrv = [String]()
    var amounts = [Double]()

    var fromCurrency: String?

    override func awakeFromNib() {
        api.loadListOfCurrencies { currencies in
            self.currencies = currencies
            self.currencies["USD"] = "US Dollar"
            self.currencyFullNames.append(contentsOf: currencies.values)

            self.getExchangeRates()
        }

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        errorLabel.isHidden = true

        fromCurrencyTextField.delegate = self
        fromCurrencyTextField.returnKeyType = .done

        toCurrencyCollectionView.dataSource = self
        toCurrencyCollectionView.register(UINib(nibName: "ToCurrencyCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ToCurrencyCell")
    }

    @IBAction func didTapFromCurrencyButton(_ sender: Any) {
        let viewController = ListOfCurrenciesViewController(currencies: currencies, delegate: self)
        self.present(viewController, animated: true)
    }


    // CurrencyProtocolDelegate

    func getFromCurrency(currency: String) {
        fromCurrency = currency
        fromCurrencyButton.titleLabel?.text = currency

        getExchangeRates(from: currency)
    }

    func getExchangeRates(from currency: String? = nil) {
        if let amount = Double(fromCurrencyTextField.text!) {
            api.getListOfExchangeRates(for: amount, from: currency) { exchangeRates, errorString  in
                if let exchangeRates = exchangeRates, errorString == nil {
                    self.toCurrencyCollectionView.isHidden = false
                    self.currencyAbrv.removeAll()
                    self.amounts.removeAll()

                    self.currencyAbrv.append(contentsOf: exchangeRates.keys)
                    self.amounts.append(contentsOf: exchangeRates.values)

                    self.toCurrencyCollectionView.reloadData()
                    self.errorLabel.isHidden = true
                } else {
                    self.toCurrencyCollectionView.isHidden = true
                    self.errorLabel.isHidden = false
                    self.errorLabel.text = errorString
                }
            }

        } else {
            print("Not a valid number: \(fromCurrencyTextField.text!)")
            errorLabel.isHidden = false
        }
    }

}

extension ViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        currencies.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ToCurrencyCell", for: indexPath) as! ToCurrencyCollectionViewCell
        cell.currencyLabel.text = String(currencyAbrv[indexPath.row].dropFirst(3))
        cell.amountLabel.text = String(amounts[indexPath.row])
        return cell
    }
}

extension ViewController: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        if fromCurrency == nil {
            fromCurrencyButton.titleLabel?.text = "USD"
        }
        getExchangeRates(from: fromCurrency)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if fromCurrency == nil {
            fromCurrencyButton.titleLabel?.text = "USD"
        }
        getExchangeRates(from: fromCurrency)
        return true
    }

}
