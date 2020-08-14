//
//  ListOfCurrenciesViewController.swift
//  CurrencyConverter
//
//  Created by Caroline Law on 8/8/20.
//  Copyright © 2020 CAL. All rights reserved.
//

import UIKit

class ListOfCurrenciesViewController: UITableViewController {

    var currencyAbrv = [String]()
    var currencyFullNames = [String]()
    let delegate: CurrencyProtocolDelegate

    init(currencies: Array<(key: String, value: String)> , delegate: CurrencyProtocolDelegate) {
        for currency in currencies {
            currencyAbrv.append(currency.key)
            currencyFullNames.append(currency.value)
        }
        
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "currencyCell")
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        currencyAbrv.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "currencyCell")! as UITableViewCell
        cell.textLabel?.text = currencyFullNames[indexPath.row]
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate.setCurrency(currency: currencyAbrv[indexPath.row])
        self.dismiss(animated: true)
    }
}
