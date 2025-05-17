import Foundation
import CoreData

class RatesRepository {
    private let coreDataStack: CoreDataStack
    private let apiClient: APIClient
    
    init(coreDataStack: CoreDataStack = .shared, apiClient: APIClient = .shared) {
        self.coreDataStack = coreDataStack
        self.apiClient = apiClient
    }
    
    // MARK: - API Operations
    
    func fetchLatestRates(base: String, completion: @escaping (Result<RatesResponse, NetworkError>) -> Void) {
        apiClient.request(endpoint: .latest(base: base), completion: completion)
    }
    
    func fetchHistoricalRates(base: String, symbol: String, days: Int, completion: @escaping (Result<HistoricalRatesResponse, NetworkError>) -> Void) {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let endDateString = dateFormatter.string(from: endDate)
        let startDateString = dateFormatter.string(from: startDate)
        
        apiClient.request(
            endpoint: .historical(
                base: base,
                symbols: symbol,
                startDate: startDateString,
                endDate: endDateString
            ),
            completion: completion
        )
    }
    
    // MARK: - Core Data Operations
    
    func saveHistoricalRates(from response: HistoricalRatesResponse, targetCurrency: String) {
        let context = coreDataStack.viewContext
        let baseCurrency = response.base
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for (dateString, rates) in response.rates {
            if let date = dateFormatter.date(from: dateString), let rate = rates[targetCurrency] {
                // Check if record already exists
                let fetchRequest: NSFetchRequest<HistoricalRate> = HistoricalRate.fetchRequest()
                fetchRequest.predicate = NSPredicate(
                    format: "baseCurrencyCode == %@ AND targetCurrencyCode == %@ AND date == %@",
                    baseCurrency, targetCurrency, date as NSDate
                )
                
                do {
                    let results = try context.fetch(fetchRequest)
                    let historicalRate: HistoricalRate
                    
                    if let existingRate = results.first {
                        historicalRate = existingRate
                    } else {
                        historicalRate = HistoricalRate(context: context)
                        historicalRate.date = date
                        historicalRate.baseCurrencyCode = baseCurrency
                        historicalRate.targetCurrencyCode = targetCurrency
                    }
                    
                    historicalRate.value = rate
                } catch {
                    print("Error saving historical rate: \(error)")
                }
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    func getHistoricalRates(baseCurrency: String, targetCurrency: String, days: Int) -> [(date: Date, value: Double)] {
        let context = coreDataStack.viewContext
        let fetchRequest: NSFetchRequest<HistoricalRate> = HistoricalRate.fetchRequest()
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
        
        fetchRequest.predicate = NSPredicate(
            format: "baseCurrencyCode == %@ AND targetCurrencyCode == %@ AND date >= %@ AND date <= %@",
            baseCurrency, targetCurrency, startDate as NSDate, endDate as NSDate
        )
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.map { (date: $0.date!, value: $0.value) }
        } catch {
            print("Error fetching historical rates: \(error)")
            return []
        }
    }
}
