import Foundation

class ConverterViewModel {
    enum CurrencyType {
        case from
        case to
    }
    
    private let currencyService = CurrencyService()
    
    private var fromCurrency: String = "USD"
    private var toCurrency: String = "EUR"
    
    var onCurrenciesUpdated: ((String, String) -> Void)?
    var onConversionResult: ((String) -> Void)?
    var onLoading: ((Bool) -> Void)?
    var onError: ((String) -> Void)?
    
    func viewDidLoad() {
        // Initialize with base currency if available
        if let baseCurrency = currencyService.getBaseCurrency()?.code {
            fromCurrency = baseCurrency
            updateCurrencies()
        }
    }
    
    func setCurrency(_ currencyCode: String, for type: CurrencyType) {
        switch type {
        case .from:
            fromCurrency = currencyCode
        case .to:
            toCurrency = currencyCode
        }
        
        updateCurrencies()
    }
    
    func swapCurrencies() {
        let temp = fromCurrency
        fromCurrency = toCurrency
        toCurrency = temp
        
        updateCurrencies()
    }
    
    func convert(amount: Double) {
        onLoading?(true)
        
        // Check if currencies are the same
        if fromCurrency == toCurrency {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = toCurrency
            
            if let formattedAmount = formatter.string(from: NSNumber(value: amount)) {
                onConversionResult?(formattedAmount)
            } else {
                onConversionResult?("\(amount) \(toCurrency)")
            }
            
            onLoading?(false)
            return
        }
        
        // Perform conversion
                if let convertedAmount = currencyService.convertCurrency(
                    amount: amount,
                    from: fromCurrency,
                    to: toCurrency
                ) {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .currency
                    formatter.currencyCode = toCurrency
                    formatter.maximumFractionDigits = 4
                    
                    if let formattedAmount = formatter.string(from: NSNumber(value: convertedAmount)) {
                        onConversionResult?(formattedAmount)
                    } else {
                        onConversionResult?("\(String(format: "%.4f", convertedAmount)) \(toCurrency)")
                    }
                } else {
                    onError?("Could not convert between these currencies. Please make sure both currencies are available.")
                }
                
                onLoading?(false)
            }
            
            private func updateCurrencies() {
                onCurrenciesUpdated?(fromCurrency, toCurrency)
                onConversionResult?("")
            }
        }
