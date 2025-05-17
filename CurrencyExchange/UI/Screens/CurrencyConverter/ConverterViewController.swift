import UIKit

class ConverterViewController: UIViewController {
    private let fromCurrencyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("USD", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .white
        button.setTitleColor(.appText, for: .normal)
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let toCurrencyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("EUR", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .white
        button.setTitleColor(.appText, for: .normal)
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let swapButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.up.arrow.down"), for: .normal)
        button.tintColor = .appPrimary
        button.backgroundColor = .white
        button.layer.cornerRadius = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let amountTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter amount"
        textField.font = UIFont.systemFont(ofSize: 24)
        textField.textAlignment = .center
        textField.keyboardType = .decimalPad
        textField.backgroundColor = .white
        textField.layer.cornerRadius = 8
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let resultLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = .appText
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let convertButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Convert", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .appPrimary
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let loadingView = LoadingView(message: "Converting...")
    
    private let viewModel = ConverterViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupBindings()
        viewModel.viewDidLoad()
    }
    
    private func setupViews() {
        view.backgroundColor = .appBackground
        title = "Currency Converter"
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        // Add subviews
        view.addSubview(fromCurrencyButton)
        view.addSubview(toCurrencyButton)
        view.addSubview(swapButton)
        view.addSubview(amountTextField)
        view.addSubview(resultLabel)
        view.addSubview(convertButton)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            fromCurrencyButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            fromCurrencyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            fromCurrencyButton.widthAnchor.constraint(equalToConstant: 100),
            
            toCurrencyButton.topAnchor.constraint(equalTo: fromCurrencyButton.topAnchor),
            toCurrencyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            toCurrencyButton.widthAnchor.constraint(equalToConstant: 100),
            
            swapButton.centerYAnchor.constraint(equalTo: fromCurrencyButton.centerYAnchor),
            swapButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            swapButton.widthAnchor.constraint(equalToConstant: 40),
            swapButton.heightAnchor.constraint(equalToConstant: 40),
            
            amountTextField.topAnchor.constraint(equalTo: fromCurrencyButton.bottomAnchor, constant: 32),
            amountTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            amountTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            amountTextField.heightAnchor.constraint(equalToConstant: 60),
            
            resultLabel.topAnchor.constraint(equalTo: amountTextField.bottomAnchor, constant: 32),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            convertButton.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 48),
            convertButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            convertButton.widthAnchor.constraint(equalToConstant: 200),
            convertButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Add button actions
        fromCurrencyButton.addTarget(self, action: #selector(fromCurrencyTapped), for: .touchUpInside)
        toCurrencyButton.addTarget(self, action: #selector(toCurrencyTapped), for: .touchUpInside)
        swapButton.addTarget(self, action: #selector(swapCurrenciesTapped), for: .touchUpInside)
        convertButton.addTarget(self, action: #selector(convertTapped), for: .touchUpInside)
        
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
        
        setupAccessibility()
    }
    
    private func setupBindings() {
        viewModel.onCurrenciesUpdated = { [weak self] fromCurrency, toCurrency in
            DispatchQueue.main.async {
                self?.fromCurrencyButton.setTitle(fromCurrency, for: .normal)
                self?.toCurrencyButton.setTitle(toCurrency, for: .normal)
            }
        }
        
        viewModel.onConversionResult = { [weak self] result in
            DispatchQueue.main.async {
                self?.resultLabel.text = result
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
                let alert = UIAlertController(
                    title: "Error",
                    message: message,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func fromCurrencyTapped() {
        showCurrencyPicker(for: .from)
    }
    
    @objc private func toCurrencyTapped() {
        showCurrencyPicker(for: .to)
    }
    
    @objc private func swapCurrenciesTapped() {
        viewModel.swapCurrencies()
    }
    
    @objc private func convertTapped() {
        guard let amountText = amountTextField.text, !amountText.isEmpty,
              let amount = Double(amountText) else {
            showAlert(message: "Please enter a valid amount")
            return
        }
        
        viewModel.convert(amount: amount)
    }
    
    private func showCurrencyPicker(for type: ConverterViewModel.CurrencyType) {
        let alertController = UIAlertController(
            title: "Select Currency",
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
            
            self?.viewModel.setCurrency(currencyCode, for: type)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func setupAccessibility() {
        fromCurrencyButton.setupAccessibility(
            label: "From currency: \(fromCurrencyButton.title(for: .normal) ?? "")",
            hint: "Tap to change the source currency",
            traits: .button
        )
        
        toCurrencyButton.setupAccessibility(
            label: "To currency: \(toCurrencyButton.title(for: .normal) ?? "")",
            hint: "Tap to change the target currency",
            traits: .button
        )
        
        swapButton.setupAccessibility(
            label: "Swap currencies",
            hint: "Tap to swap the source and target currencies",
            traits: .button
        )
        
        amountTextField.setupAccessibility(
            label: "Amount to convert",
            hint: "Enter the amount you want to convert",
            traits: .searchField
        )
        
        resultLabel.setupAccessibility(
            label: "Conversion result",
            traits: .staticText
        )
        
        convertButton.setupAccessibility(
            label: "Convert",
            hint: "Tap to perform the currency conversion",
            traits: .button
        )
    }
}
