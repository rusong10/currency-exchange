import Foundation

struct HistoricalRatesResponse: Codable {
    let success: Bool
    let timeseries: Bool
    let base: String
    let startDate: String
    let endDate: String
    let rates: [String: [String: Double]]
    
    enum CodingKeys: String, CodingKey {
        case success, timeseries, base
        case startDate = "start_date"
        case endDate = "end_date"
        case rates
    }
}
