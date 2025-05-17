import Foundation

enum APIEndpoint {
    case latest(base: String)
    case convert(from: String, to: String, amount: Double)
    case historical(base: String, symbols: String, startDate: String, endDate: String)
    
    private var baseURL: String {
        return "https://api.exchangeratesapi.io/v1"
    }
    
    private var path: String {
        switch self {
        case .latest:
            return "/latest"
        case .convert:
            return "/convert"
        case .historical:
            return "/timeseries"
        }
    }
    
    var url: URL {
        return URL(string: baseURL + path)!
    }
    
    var parameters: [String: Any] {
        let apiKey = "aada0b45a54cf472e887ad97391f2ff2"
        
        var params: [String: Any] = ["access_key": apiKey]
        
        switch self {
        case .latest(let base):
            params["base"] = base
        case .convert(let from, let to, let amount):
            params["from"] = from
            params["to"] = to
            params["amount"] = amount
        case .historical(let base, let symbols, let startDate, let endDate):
            params["base"] = base
            params["symbols"] = symbols
            params["start_date"] = startDate
            params["end_date"] = endDate
        }
        
        return params
    }
}
