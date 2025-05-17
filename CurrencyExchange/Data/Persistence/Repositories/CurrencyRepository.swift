import Foundation
import CoreData

class CurrencyRepository {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }
    
    // MARK: - Read Operations
    
    func getAllCurrencies() -> [Currency] {
        let fetchRequest: NSFetchRequest<Currency> = Currency.fetchRequest()
        
        do {
            return try coreDataStack.viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching currencies: \(error)")
            return []
        }
    }
    
    func getBaseCurrency() -> Currency? {
        let fetchRequest: NSFetchRequest<Currency> = Currency.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isBase == %@", NSNumber(value: true))
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try coreDataStack.viewContext.fetch(fetchRequest)
            return results.first
        } catch {
            print("Error fetching base currency: \(error)")
            return nil
        }
    }
    
    // MARK: - Write Operations
    
    func setBaseCurrency(code: String) {
        let context = coreDataStack.viewContext
        
        // Reset all currencies to non-base
        let resetRequest: NSFetchRequest<Currency> = Currency.fetchRequest()
        resetRequest.predicate = NSPredicate(format: "isBase == %@", NSNumber(value: true))
        
        do {
            let baseCurrencies = try context.fetch(resetRequest)
            for currency in baseCurrencies {
                currency.isBase = false
            }
            
            // Set new base currency
            let newBaseRequest: NSFetchRequest<Currency> = Currency.fetchRequest()
            newBaseRequest.predicate = NSPredicate(format: "code == %@", code)
            
            let results = try context.fetch(newBaseRequest)
            if let newBase = results.first {
                newBase.isBase = true
            } else {
                // Create if doesn't exist
                let newCurrency = Currency(context: context)
                newCurrency.code = code
                newCurrency.isBase = true
            }
            
            try context.save()
        } catch {
            print("Error setting base currency: \(error)")
        }
    }
    
    func saveCurrencies(from response: RatesResponse) {
        let context = coreDataStack.viewContext
        let baseCurrencyCode = response.base
        
        // Save base currency
        var baseCurrency: Currency
        let baseRequest: NSFetchRequest<Currency> = Currency.fetchRequest()
        baseRequest.predicate = NSPredicate(format: "code == %@", baseCurrencyCode)
        
        do {
            let results = try context.fetch(baseRequest)
            if let existingBase = results.first {
                baseCurrency = existingBase
                baseCurrency.isBase = true
                baseCurrency.lastUpdated = Date()
            } else {
                baseCurrency = Currency(context: context)
                baseCurrency.code = baseCurrencyCode
                baseCurrency.isBase = true
                baseCurrency.lastUpdated = Date()
            }
            
            // Save rates
            for (currencyCode, rateValue) in response.rates {
                let rateRequest: NSFetchRequest<Rate> = Rate.fetchRequest()
                rateRequest.predicate = NSPredicate(format: "currencyCode == %@ AND baseCurrency == %@",
                                                   currencyCode, baseCurrency)
                
                let results = try context.fetch(rateRequest)
                let rate: Rate
                
                if let existingRate = results.first {
                    rate = existingRate
                } else {
                    rate = Rate(context: context)
                    rate.currencyCode = currencyCode
                    rate.baseCurrency = baseCurrency
                }
                
                rate.value = rateValue
                rate.date = Date()
            }
            
            try context.save()
        } catch {
            print("Error saving currencies: \(error)")
        }
    }
}
