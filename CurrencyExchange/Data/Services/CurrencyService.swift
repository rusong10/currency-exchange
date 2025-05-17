import Foundation
import Alamofire

class CurrencyService {
    private let currencyRepository: CurrencyRepository
    private let ratesRepository: RatesRepository
    
    init(currencyRepository: CurrencyRepository = CurrencyRepository(),
         ratesRepository: RatesRepository = RatesRepository()) {
        self.currencyRepository = currencyRepository
        self.ratesRepository = ratesRepository
    }
    
    // MARK: - Public Methods
    
    func getBaseCurrency() -> Currency? {
        let baseCurrency = currencyRepository.getBaseCurrency()
        
        // Default to EUR if no base currency is set
        if baseCurrency == nil {
            currencyRepository.setBaseCurrency(code: "EUR")
            return currencyRepository.getBaseCurrency()
        }
        
        return baseCurrency
    }
    
    func getAllCurrencies() -> [Currency] {
        return currencyRepository.getAllCurrencies()
    }
    
    func setBaseCurrency(code: String) {
        currencyRepository.setBaseCurrency(code: code)
    }
    
    func refreshRates(completion: @escaping (Result<Void, NetworkError>) -> Void) {
        // Check network connectivity
        if !NetworkReachabilityManager()!.isReachable {
            // If offline, try to use cached data
            if let baseCurrency = getBaseCurrency(), baseCurrency.rates?.count ?? 0 > 0 {
                completion(.success(()))
            } else {
                completion(.failure(.noInternet))
            }
            return
        }
        
        guard let baseCurrency = getBaseCurrency() else {
            completion(.failure(.invalidResponse))
            return
        }
        
        ratesRepository.fetchLatestRates(base: baseCurrency.code!) { [weak self] result in
            switch result {
            case .success(let response):
                self?.currencyRepository.saveCurrencies(from: response)
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func convertCurrency(amount: Double, from: String, to: String) -> Double? {
        // Get the rates for the base currency
        guard let baseCurrency = currencyRepository.getBaseCurrency(),
              let baseCurrencyCode = baseCurrency.code else {
            return nil
        }
        
        // If converting from base currency
        if from == baseCurrencyCode {
            let fetchRequest = Rate.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "currencyCode == %@ AND baseCurrency == %@",
                                               to, baseCurrency)
            
            do {
                let results = try CoreDataStack.shared.viewContext.fetch(fetchRequest)
                if let rate = results.first {
                    return amount * rate.value
                }
            } catch {
                print("Error fetching rate: \(error)")
            }
        }
        // If converting to base currency
        else if to == baseCurrencyCode {
            let fetchRequest = Rate.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "currencyCode == %@ AND baseCurrency == %@",
                                               from, baseCurrency)
            
            do {
                let results = try CoreDataStack.shared.viewContext.fetch(fetchRequest)
                if let rate = results.first, rate.value > 0 {
                    return amount / rate.value
                }
            } catch {
                print("Error fetching rate: \(error)")
            }
        }
        // If converting between two non-base currencies
        else {
            let fromFetchRequest = Rate.fetchRequest()
            fromFetchRequest.predicate = NSPredicate(format: "currencyCode == %@ AND baseCurrency == %@",
                                                   from, baseCurrency)
            
            let toFetchRequest = Rate.fetchRequest()
            toFetchRequest.predicate = NSPredicate(format: "currencyCode == %@ AND baseCurrency == %@",
                                                 to, baseCurrency)
            
            do {
                let fromResults = try CoreDataStack.shared.viewContext.fetch(fromFetchRequest)
                let toResults = try CoreDataStack.shared.viewContext.fetch(toFetchRequest)
                
                if let fromRate = fromResults.first, let toRate = toResults.first, fromRate.value > 0 {
                    // Convert from source to base, then from base to target
                    let amountInBase = amount / fromRate.value
                    return amountInBase * toRate.value
                }
            } catch {
                print("Error fetching rates: \(error)")
            }
        }
        
        return nil
    }
    
    func fetchHistoricalRates(targetCurrency: String, days: Int = 7, completion: @escaping (Result<[(date: Date, value: Double)], NetworkError>) -> Void) {
        guard let baseCurrency = getBaseCurrency()?.code else {
            completion(.failure(.invalidResponse))
            return
        }
        
        // First check if we have cached data
        let cachedRates = ratesRepository.getHistoricalRates(
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency,
            days: days
        )
        
        // If we have enough cached data, return it
        if cachedRates.count >= days - 1 {
            completion(.success(cachedRates))
            return
        }
        
        // Otherwise fetch from API
        ratesRepository.fetchHistoricalRates(base: baseCurrency, symbol: targetCurrency, days: days) { [weak self] result in
            switch result {
            case .success(let response):
                self?.ratesRepository.saveHistoricalRates(from: response, targetCurrency: targetCurrency)
                
                // Get the updated data from Core Data
                let updatedRates = self?.ratesRepository.getHistoricalRates(
                    baseCurrency: baseCurrency,
                    targetCurrency: targetCurrency,
                    days: days
                ) ?? []
                
                completion(.success(updatedRates))
                
            case .failure(let error):
                // If API fails but we have some cached data, return what we have
                if !cachedRates.isEmpty {
                    completion(.success(cachedRates))
                } else {
                    completion(.failure(error))
                }
            }
        }
    }
}
