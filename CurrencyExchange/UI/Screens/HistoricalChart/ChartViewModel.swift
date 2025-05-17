import Foundation
import DGCharts
import Charts

class ChartViewModel {
    let baseCurrencyCode: String
    let targetCurrencyCode: String
    
    private let currencyService = CurrencyService()
    private let days = 7
    
    var onChartDataUpdated: (([ChartDataEntry], [Date]) -> Void)?
    var onInfoUpdated: ((String) -> Void)?
    var onLoading: ((Bool) -> Void)?
    var onError: ((String) -> Void)?
    
    init(baseCurrencyCode: String, targetCurrencyCode: String) {
        self.baseCurrencyCode = baseCurrencyCode
        self.targetCurrencyCode = targetCurrencyCode
    }
    
    func viewDidLoad() {
        loadHistoricalData()
    }
    
    func refreshData() {
        loadHistoricalData(forceRefresh: true)
    }
    
    private func loadHistoricalData(forceRefresh: Bool = false) {
        onLoading?(true)
        
        currencyService.fetchHistoricalRates(
            targetCurrency: targetCurrencyCode,
            days: days,
            completion: { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let historicalRates):
                    if historicalRates.isEmpty {
                        self.onError?("No historical data available for this currency pair.")
                    } else {
                        self.processHistoricalData(historicalRates)
                    }
                case .failure(let error):
                    self.onError?(error.localizedDescription)
                }
                
                self.onLoading?(false)
            }
        )
    }
    
    private func processHistoricalData(_ historicalRates: [(date: Date, value: Double)]) {
        // Sort by date
        let sortedRates = historicalRates.sorted { $0.date < $1.date }
        
        // Create chart entries
        var entries: [ChartDataEntry] = []
        var dates: [Date] = []
        
        for (index, rate) in sortedRates.enumerated() {
            let entry = ChartDataEntry(x: Double(index), y: rate.value)
            entries.append(entry)
            dates.append(rate.date)
        }
        
        // Calculate statistics
        if let minRate = sortedRates.min(by: { $0.value < $1.value }),
           let maxRate = sortedRates.max(by: { $0.value < $1.value }) {
            
            let avgRate = sortedRates.reduce(0.0) { $0 + $1.value } / Double(sortedRates.count)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd, yyyy"
            
            let info = """
            Historical data for \(targetCurrencyCode) per \(baseCurrencyCode) over the last \(days) days:
            
            Minimum: \(String(format: "%.4f", minRate.value)) on \(dateFormatter.string(from: minRate.date))
            Maximum: \(String(format: "%.4f", maxRate.value)) on \(dateFormatter.string(from: maxRate.date))
            Average: \(String(format: "%.4f", avgRate))
            """
            
            onInfoUpdated?(info)
        }
        
        onChartDataUpdated?(entries, dates)
    }
}
