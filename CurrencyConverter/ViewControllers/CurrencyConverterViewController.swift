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

class CurrencyConverterViewController: UIViewController, CurrencyProtocolDelegate {

    @IBOutlet var fromCurrencyTextField: UITextField!
    @IBOutlet var fromCurrencyButton: UIButton!
    @IBOutlet var toCurrencyCollectionView: UICollectionView!
    @IBOutlet var errorLabel: UILabel!

    private var api = CurrencyAPI()
    private var currencies = [String: String]()
    private var sortedCurrencies = Array<(key: String, value: String)>()
    private var currencyAbrv = [String]()
    private var currencyFullNames = [String]()
    private var amounts = [Double]()
    private var fromCurrency: String = "USD"

    override func awakeFromNib() {

        api.loadListOfCurrencies { currencies in
            self.currencies = currencies
            self.getExchangeRates(from: "USD")

            self.sortedCurrencies = currencies.sorted(by: {$0.key < $1.key})
            for currency in self.sortedCurrencies {
                self.currencyFullNames.append(currency.value)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addDoneButtonOnKeyboard()
        fromCurrencyButton.contentHorizontalAlignment = .right
        errorLabel.isHidden = true

        fromCurrencyTextField.delegate = self
        fromCurrencyTextField.returnKeyType = .done

        toCurrencyCollectionView.dataSource = self
        toCurrencyCollectionView.register(UINib(nibName: "ToCurrencyCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ToCurrencyCell")
    }

    @IBAction func didTapFromCurrencyButton(_ sender: Any) {
        let viewController = ListOfCurrenciesViewController(currencies: sortedCurrencies, delegate: self)
        self.present(viewController, animated: true)
    }

    // CurrencyProtocolDelegate
    func getFromCurrency(currency: String) {
        fromCurrency = currency
        fromCurrencyButton.setTitle(currency, for: .normal)

        getExchangeRates(from: currency)
    }

    func getExchangeRates(from currency: String) {
        if let amount = Double(fromCurrencyTextField.text!) {
            api.getListOfExchangeRates(for: amount, from: currency) { exchangeRates, error  in
                if let exchangeRates = exchangeRates, error == nil {
                    self.toCurrencyCollectionView.isHidden = false
                    self.currencyAbrv.removeAll()
                    self.amounts.removeAll()

                    let rates = exchangeRates.sorted { (first, second) -> Bool in
                        first < second
                    }

                    for rate in rates {
                        self.currencyAbrv.append(rate.key)
                        self.amounts.append(rate.value)
                    }

                    self.toCurrencyCollectionView.reloadData()
                    self.errorLabel.isHidden = true

                } else {

                    self.toCurrencyCollectionView.isHidden = true
                    self.errorLabel.isHidden = false
                    self.errorLabel.text = error?.errorDescription
                }
            }

        } else {
            print("Not a valid number: \(fromCurrencyTextField.text!)")
            errorLabel.isHidden = false
            self.toCurrencyCollectionView.isHidden = true
            errorLabel.text = "Please enter a number"
        }
    }

}

// UICollectionViewDataSource
extension CurrencyConverterViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        currencies.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ToCurrencyCell", for: indexPath) as! ToCurrencyCollectionViewCell
        cell.currencyLabel.text = String(currencyAbrv[indexPath.row].dropFirst(3))
        cell.fullNameLabel.text = currencyFullNames[indexPath.row]
        cell.amountLabel.text = String(format: "%.2f", amounts[indexPath.row])
        return cell
    }
}

// UITextFieldDelegate
extension CurrencyConverterViewController: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()

        fromCurrencyButton.setTitle(fromCurrency, for: .normal)
        getExchangeRates(from: fromCurrency)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        fromCurrencyButton.setTitle(fromCurrency, for: .normal)
        getExchangeRates(from: fromCurrency)
        return true
    }

    func addDoneButtonOnKeyboard(){
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done",
                                                    style: .done,
                                                    target: self,
                                                    action: #selector(self.doneButtonAction))

        doneToolbar.items = [flexSpace, done]
        doneToolbar.sizeToFit()

        fromCurrencyTextField.inputAccessoryView = doneToolbar
    }

    @objc func doneButtonAction(){
        fromCurrencyTextField.resignFirstResponder()
    }

}
