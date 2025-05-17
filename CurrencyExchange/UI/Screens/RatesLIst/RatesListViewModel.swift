import Foundation

struct RateViewModel {
    let currencyCode: String
    let value: Double
}

class RatesListViewModel {
    private let currencyService = CurrencyService()
    
    var rates: [RateViewModel] = []
    var baseCurrency: String?
    
    var onRatesUpdated: (() -> Void)?
    var onLoading: ((Bool) -> Void)?
    var onError: ((String) -> Void)?
    
    func viewDidLoad() {
        loadRates()
    }
    
    func loadRates() {
        onLoading?(true)
        
        // Get base currency
        if let currency = currencyService.getBaseCurrency() {
            baseCurrency = currency.code
            
            // Get rates from Core Data
            if let rates = currency.rates?.allObjects as? [Rate], !rates.isEmpty {
                self.rates = rates.map { rate in
                    RateViewModel(
                        currencyCode: rate.currencyCode ?? "",
                        value: rate.value
                    )
                }.sorted { $0.currencyCode < $1.currencyCode }
                
                onRatesUpdated?()
                onLoading?(false)
            } else {
                // No cached rates, fetch from API
                refreshRates()
            }
        } else {
            // No base currency set, use default and fetch rates
            refreshRates()
        }
    }
    
    func refreshRates() {
        onLoading?(true)
        
        currencyService.refreshRates { [weak self] result in
            switch result {
            case .success:
                self?.loadRates()
            case .failure(let error):
                self?.onError?(error.localizedDescription)
                self?.onLoading?(false)
            }
        }
    }
    
    func changeBaseCurrency(to currencyCode: String) {
        onLoading?(true)
        
        currencyService.setBaseCurrency(code: currencyCode)
        baseCurrency = currencyCode
        
        refreshRates()
    }
}
