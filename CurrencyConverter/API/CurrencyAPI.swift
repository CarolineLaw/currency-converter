//
//  CurrencyAPI.swift
//  CurrencyConverter
//
//  Created by Caroline Law on 8/8/20.
//  Copyright © 2020 CAL. All rights reserved.
//

import Foundation
import Combine

class CurrencyAPI {

    enum CurrencyError: LocalizedError {
        case apiError(message: String)

        var errorDescription: String? {
            switch self {
            case let .apiError(message):
                return message
            }
        }
    }

    private let session = URLSession.shared
    private let baseURL = "api.currencylayer.com"
    private let accessKey = "bd3ad620cc343a1289b2ac25e6ac0eca"

    private var currenciesAbrv = [String]()

    private let userDefaults = UserDefaults.standard
    private let exchangeRatesForSourceKey = "exchangeRatesForSourceKey"
    private let sourceTimestampKey = "sourceTimeStampKey"
    private let thirtyMinutes = 1800.0
    

    private func url(with queryItems: [URLQueryItem]?, path: String) -> URL {
        var components = URLComponents()
        components.scheme = "http"
        components.host = baseURL
        components.path = "/" + path

        components.queryItems = [URLQueryItem(name: "access_key", value: accessKey)]

        if let queryItems = queryItems {
            components.queryItems?.append(contentsOf: queryItems)
        }

         guard let url = components.url else {
            preconditionFailure("Failure to construct URL")
        }

        return url
    }

    private func load(url: URL, completionHandler: @escaping (Result<Data, Error>) -> Void) {
        let task = self.session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
            if let error = error {
                    completionHandler(.failure(error))
                } else if let data = data {
                    completionHandler(.success(data))

                } else {
                    let error = NSError(domain: "other error", code: 0, userInfo: nil)
                    completionHandler(.failure(error))
                }
            }
        }

        task.resume()
    }

    func loadListOfCurrencies(completionHandler: @escaping ([String: String]) -> Void) {
        load(url: url(with: nil, path: "list")) { result in
            switch result {
            case .success(let data):
                let currenciesData = try? JSONDecoder().decode(CurrenciesResponse.self, from: data)
                if let theData = currenciesData?.currencies {
                    completionHandler(theData)
                } else {
                    print("Currencies couldn't be fetched")
                }
            case.failure(let error):
                print(error.localizedDescription)
            }
        }
    }

    private func loadExchangeRates(source: String, completionHandler: @escaping([String: Double]?, CurrencyError?) -> Void) {
        if let sourceTimestamp = userDefaults.object(forKey: sourceTimestampKey) as? [String: Date],
            let timeInterval = sourceTimestamp[source]?.timeIntervalSinceNow,
            -timeInterval < thirtyMinutes, // Check if the time interval is less than 30 minutes

            let exchangeRatesForSource = userDefaults.object(forKey: exchangeRatesForSourceKey) as? [String: String],
            exchangeRatesForSource.keys.contains(source) {  // Check userDefaults for exchange rates of source first
                guard let exchangeRatesJson = exchangeRatesForSource[source]?.utf8 else {
                    completionHandler(nil, CurrencyError.apiError(message: "Couldn't read the exchange rates JSON"))
                    return
                }

                let exchangeRatesData = try? JSONDecoder().decode(ExchangesResponse.self, from: Data(exchangeRatesJson))
                handleData(exchangesResponse: exchangeRatesData, completionHandler: completionHandler)

        } else { // Could not find source in exchangeRatesForSource
            let query = URLQueryItem(name: "currencies", value: currenciesAbrv.joined(separator: ", "))
            var queries = [URLQueryItem]()
            queries = [query, URLQueryItem(name: "source", value: source), URLQueryItem(name: "format", value: "1")]

            load(url: url(with: queries, path: "live")) { result in
                switch result {
                case .success(let data):
                    // Store the JSON for source
                    let exchangeRatesJson = String(decoding: data, as: UTF8.self)
                    self.userDefaults.setValue([source: exchangeRatesJson], forKey: self.exchangeRatesForSourceKey)
                    let sourceTimestamp = [source: Date()]
                    self.userDefaults.setValue(sourceTimestamp, forKey: self.sourceTimestampKey)

                    let exchangeRatesData = try? JSONDecoder().decode(ExchangesResponse.self , from: data)
                    self.handleData(exchangesResponse: exchangeRatesData, completionHandler: completionHandler)
                    
                case .failure(let error):
                    completionHandler(nil, CurrencyError.apiError(message: error.localizedDescription))
                }
            }

        }
    }

    private func handleData(exchangesResponse: ExchangesResponse?, completionHandler: @escaping ([String: Double]?, CurrencyError?) -> Void) {
        if let theData = exchangesResponse?.quotes {
            completionHandler(theData, nil)
        } else {
            if let error = exchangesResponse?.error?.info {
                completionHandler(nil, CurrencyError.apiError(message: error))
            }
        }
    }

    func getListOfExchangeRates(for amount: Double, from source: String, completionHandler: @escaping([String: Double]?, CurrencyError?) -> Void) {
        var amounts = [String: Double]()
        loadExchangeRates(source: source) { exchangeRates, error  in
            guard let exchangeRates = exchangeRates else {
                completionHandler(nil, error)
                return
            }

            for rate in exchangeRates {
                amounts[rate.key] = rate.value * amount
            }

            completionHandler(amounts, nil)

        }
    }

}
