//
//  CurrencyConverterViewController.swift
//  CurrencyConverter
//
//  Created by Caroline Law on 8/8/20.
//  Copyright © 2020 CAL. All rights reserved.
//

import UIKit
import Combine

protocol CurrencyProtocolDelegate: AnyObject {
    func setCurrency(currency: String)
}

class CurrencyConverterViewController: UIViewController, CurrencyProtocolDelegate {

    @IBOutlet var fromCurrencyTextField: UITextField!
    @IBOutlet var fromCurrencyButton: UIButton!
    @IBOutlet var toCurrencyCollectionView: UICollectionView!
    @IBOutlet var errorLabel: UILabel!

    // Put this in a proper view model
    private var api = CurrencyAPI()
    private var currencies = [String: String]()
    private var sortedCurrencies = Array<(key: String, value: String)>()
    private var currencyAbrv = [String]()
    private var currencyFullNames = [String]()
    private var amounts = [Double]()
    private var typedValue: Int = 0

    private var cancellable = Set<AnyCancellable>()

    private var viewModel: CurrencyViewModel = CurrencyViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        addDoneButtonOnKeyboard()

        api.loadListOfCurrencies { currencies in
            self.currencies = currencies

            self.sortedCurrencies = currencies.sorted(by: {$0.key < $1.key})
            for currency in self.sortedCurrencies {
                self.currencyFullNames.append(currency.value)
                self.viewModel.amount = 0
                self.viewModel.sourceCurrency = "USD"
            }
        }

        fromCurrencyButton.contentHorizontalAlignment = .right
        errorLabel.isHidden = true

        fromCurrencyTextField.delegate = self
        fromCurrencyTextField.returnKeyType = .done
        fromCurrencyTextField.textAlignment = .right
        fromCurrencyTextField.addTarget(self, action: #selector(myTextFieldDidChange), for: .editingChanged)

        toCurrencyCollectionView.dataSource = self
        toCurrencyCollectionView.register(UINib(nibName: "ToCurrencyCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ToCurrencyCell")

        viewModel.$sourceCurrency.sink() { currency in
            self.fromCurrencyButton.setTitle(currency, for: .normal)
        }.store(in: &cancellable)

        viewModel.$amountString.sink() { amount in
            self.fromCurrencyTextField.text = amount
        }.store(in: &cancellable)

        viewModel.$error.sink() { error in
            guard let error = error else {
                self.errorLabel.isHidden = true
                return
            }
            self.toCurrencyCollectionView.isHidden = true
            self.errorLabel.isHidden = false
            self.errorLabel.text = error
        }.store(in: &cancellable)

        Publishers.CombineLatest(viewModel.$exchangeRates, viewModel.$amount).sink() { rates, amount in
            guard let rates = rates, let amount = amount else {
                self.toCurrencyCollectionView.isHidden = true
                return
            }

            self.toCurrencyCollectionView.isHidden = false
            self.currencyAbrv.removeAll()
            self.amounts.removeAll()

            for rate in rates.sorted(by: {$0.key < $1.key}) {
                self.currencyAbrv.append(rate.key)
                self.amounts.append(rate.value * amount)
            }

            self.toCurrencyCollectionView.reloadData()
        }.store(in: &cancellable)

    }

    @IBAction func didTapFromCurrencyButton(_ sender: Any) {
        let viewController = ListOfCurrenciesViewController(currencies: sortedCurrencies)
        viewController.delegate = self
        self.present(viewController, animated: true)
    }

    // CurrencyProtocolDelegate
    func setCurrency(currency: String) {
        viewModel.sourceCurrency = currency
    }

}

// UICollectionViewDataSource
extension CurrencyConverterViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        currencyAbrv.count
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

        viewModel.amountString = textField.text ?? ""
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        viewModel.amountString = textField.text ?? ""
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

    @objc func myTextFieldDidChange(_ textField: UITextField) {
        if let amountString = textField.text?.currencyInputFormatting() {
            viewModel.amountString = amountString
        }
    }
}

extension String {

    // formatting text for currency textField
    func currencyInputFormatting() -> String {

        var number: NSNumber!
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        var amountWithPrefix = self

        // remove special characters from String
        let regex = try! NSRegularExpression(pattern: "[^0-9]", options: .caseInsensitive)
        amountWithPrefix = regex.stringByReplacingMatches(in: amountWithPrefix, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.count), withTemplate: "")

        let double = (amountWithPrefix as NSString).doubleValue
        number = NSNumber(value: (double / 100))

        // if first number is 0 or all numbers were deleted
        guard number != 0 as NSNumber else {
            return ""
        }

        return formatter.string(from: number)!
    }
}
