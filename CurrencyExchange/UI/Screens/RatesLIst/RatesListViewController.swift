import UIKit

class RatesListViewController: UIViewController {
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(CurrencyCell.self, forCellReuseIdentifier: CurrencyCell.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let refreshControl = UIRefreshControl()
    
    private let loadingView = LoadingView()
    private var errorView: ErrorView?
    
    private let viewModel = RatesListViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupBindings()
        viewModel.viewDidLoad()
    }
    
    private func setupViews() {
        view.backgroundColor = .appBackground
        title = "Currency Exchange"
        
        // Add change base currency button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Change Base",
            style: .plain,
            target: self,
            action: #selector(changeBaseCurrencyTapped)
        )
        
        // Add converter button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.left.arrow.right"),
            style: .plain,
            target: self,
            action: #selector(openConverterTapped)
        )
        
        // Setup table view
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.dataSource = self
        tableView.delegate = self
        
        // Setup refresh control
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        // Setup loading view
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)
        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        loadingView.isHidden = true
    }
    
    private func setupBindings() {
        viewModel.onRatesUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                self?.refreshControl.endRefreshing()
                self?.updateTitle()
            }
        }
        
        viewModel.onLoading = { [weak self] isLoading in
            DispatchQueue.main.async {
                if isLoading {
                    self?.loadingView.startAnimating()
                } else {
                    self?.loadingView.stopAnimating()
                }
            }
        }
        
        viewModel.onError = { [weak self] message in
            DispatchQueue.main.async {
                self?.showError(message: message)
                self?.refreshControl.endRefreshing()
            }
        }
    }
    
    private func updateTitle() {
        if let baseCurrency = viewModel.baseCurrency {
            title = "Base: \(baseCurrency)"
        } else {
            title = "Currency Exchange"
        }
    }
    
    private func showError(message: String) {
        errorView?.removeFromSuperview()
        
        let errorView = ErrorView(message: message)
        errorView.translatesAutoresizingMaskIntoConstraints = false
        errorView.retryAction = { [weak self] in
            self?.viewModel.refreshRates()
            errorView.removeFromSuperview()
            self?.errorView = nil
        }
        
        view.addSubview(errorView)
        NSLayoutConstraint.activate([
            errorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        self.errorView = errorView
    }
    
    @objc private func refreshData() {
        viewModel.refreshRates()
    }
    
    @objc private func changeBaseCurrencyTapped() {
        let alertController = UIAlertController(
            title: "Select Base Currency",
            message: "Enter the 3-letter currency code",
            preferredStyle: .alert
        )
        
        alertController.addTextField { textField in
            textField.placeholder = "e.g. USD, EUR, GBP"
            textField.autocapitalizationType = .allCharacters
            textField.textAlignment = .center
        }
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { [weak self, weak alertController] _ in
            guard let textField = alertController?.textFields?.first,
                  let currencyCode = textField.text?.uppercased(),
                  currencyCode.count == 3 else {
                return
            }
            
            self?.viewModel.changeBaseCurrency(to: currencyCode)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    @objc private func openConverterTapped() {
        let converterVC = ConverterViewController()
        navigationController?.pushViewController(converterVC, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension RatesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rates.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CurrencyCell.reuseIdentifier, for: indexPath) as? CurrencyCell else {
            return UITableViewCell()
        }
        
        let rate = viewModel.rates[indexPath.row]
        cell.configure(
            currencyCode: rate.currencyCode,
            currencyName: getCurrencyName(for: rate.currencyCode),
            rate: rate.value
        )
        
        return cell
    }
    
    private func getCurrencyName(for code: String) -> String? {
        let locale = NSLocale(localeIdentifier: "en_US")
        return locale.displayName(forKey: .currencyCode, value: code)
    }
}

// MARK: - UITableViewDelegate
extension RatesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rate = viewModel.rates[indexPath.row]
        let chartVC = ChartViewController(
            baseCurrencyCode: viewModel.baseCurrency ?? "EUR",
            targetCurrencyCode: rate.currencyCode
        )
        navigationController?.pushViewController(chartVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}
