//
//  ExchangeRatesCache.swift
//  CurrencyConverter
//
//  Created by Caroline Law on 8/10/20.
//  Copyright © 2020 CAL. All rights reserved.
//

import Foundation

class ExchangeRates {
    let rates: [String: String]

    init(rates: [String: String]) {
        self.rates = rates
    }
}
