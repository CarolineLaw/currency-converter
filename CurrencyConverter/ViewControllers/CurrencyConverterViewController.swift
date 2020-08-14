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
    func setCurrency(currency: String)
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
    private var typedValue: Int = 0

    var viewModel: CurrencyViewModel = CurrencyViewModel()

    class CurrencyViewModel: ObservableObject {
        @Published var sourceCurrency: String = "USD" {
            didSet {
                updateSourceCurrency()
            }
        }

        @Published var amountString: String = "" {
            didSet {
                amount = Double(amountString.replacingOccurrences(of: " ", with: ""))
            }
        }

        @Published var amount : Double?

        @Published var exchangeRates : [String: Double]? = nil
        @Published var error : String? = nil

        private var api = CurrencyAPI()


        func updateSourceCurrency() {
            if let amount = amount {
                api.getListOfExchangeRates(from: sourceCurrency) { exchangeRates, error  in
                    if error == nil {
                        self.exchangeRates = exchangeRates
                        self.error = nil
                    } else {
                        self.exchangeRates = nil
                        self.error = error?.errorDescription
                    }
                }

            } else {
                print("Not a valid number: \(amountString)")
                error = "Please enter a number and pick a currency"
            }

        }
    }

    override func awakeFromNib() {

        api.loadListOfCurrencies { currencies in
            self.currencies = currencies
//            self.getExchangeRates(from: "USD")

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
        fromCurrencyTextField.textAlignment = .right
        fromCurrencyTextField.addTarget(self, action: #selector(myTextFieldDidChange), for: .editingChanged)

        toCurrencyCollectionView.dataSource = self
        toCurrencyCollectionView.register(UINib(nibName: "ToCurrencyCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ToCurrencyCell")


        viewModel.$sourceCurrency.sink() { currency in
            self.fromCurrencyButton.setTitle(currency, for: .normal)
        }

        viewModel.$error.sink() { error in
            guard let error = error else {
                self.errorLabel.isHidden = true
                return
            }
            self.toCurrencyCollectionView.isHidden = true
            self.errorLabel.isHidden = false
            self.errorLabel.text = error
        }

        Publishers.CombineLatest(viewModel.$exchangeRates, viewModel.$amount).sink() { rates, amount in
            guard let rates = rates, let amount = amount else {
                self.toCurrencyCollectionView.isHidden = true
                return
            }

            // TODO: add sorting back in
            self.toCurrencyCollectionView.isHidden = false
            self.currencyAbrv.removeAll()
            self.amounts.removeAll()

            self.currencyAbrv.append(contentsOf: rates.keys)
            self.amounts.append(contentsOf: rates.values.map{ $0 * amount })

            self.toCurrencyCollectionView.reloadData()
        }

    }

    @IBAction func didTapFromCurrencyButton(_ sender: Any) {
        let viewController = ListOfCurrenciesViewController(currencies: sortedCurrencies, delegate: self)
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
            textField.text = amountString
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
