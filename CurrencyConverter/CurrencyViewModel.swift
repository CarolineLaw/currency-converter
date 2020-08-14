//
//  CurrencyViewModel.swift
//  CurrencyConverter
//
//  Created by Caroline Law on 8/8/20.
//  Copyright © 2020 CAL. All rights reserved.
//

import Foundation
import Combine

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
        api.getListOfExchangeRates(from: sourceCurrency) { exchangeRates, error  in
            if error == nil {
                self.exchangeRates = exchangeRates
                self.error = nil
            } else {
                self.exchangeRates = nil
                self.error = error?.errorDescription
            }
        }
    }
}
