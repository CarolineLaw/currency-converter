//
//  ListOfCurrenciesResponse.swift
//  CurrencyConverter
//
//  Created by Caroline Law on 8/8/20.
//  Copyright © 2020 CAL. All rights reserved.
//

import Foundation

struct CurrenciesResponse: Decodable {
    let success: Bool
    let currencies: [String: String]
}
