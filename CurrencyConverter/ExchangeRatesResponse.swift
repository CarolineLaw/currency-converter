//
//  ExchangeRatesResponse.swift
//  CurrencyConverter
//
//  Created by Caroline Law on 8/9/20.
//  Copyright © 2020 CAL. All rights reserved.
//

import Foundation

struct ExchangesResponse: Decodable {
    let success: Bool
    let quotes: [String: Double]?
    let error: ExchangeError?

    struct ExchangeError: Decodable {
        let info: String
    }
}

