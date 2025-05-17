import Foundation
import Alamofire

class NetworkMonitor {
    static let shared = NetworkMonitor()
    
    private let reachabilityManager: NetworkReachabilityManager?
    private var isReachable: Bool = true
    
    var onNetworkStatusChanged: ((Bool) -> Void)?
    
    private init() {
        reachabilityManager = NetworkReachabilityManager()
        
        startMonitoring()
    }
    
    func startMonitoring() {
        reachabilityManager?.startListening(onUpdatePerforming: { [weak self] status in
            switch status {
            case .notReachable:
                self?.isReachable = false
                self?.onNetworkStatusChanged?(false)
            case .reachable, .unknown:
                self?.isReachable = true
                self?.onNetworkStatusChanged?(true)
            }
        })
    }
    
    func stopMonitoring() {
        reachabilityManager?.stopListening()
    }
    
    var isNetworkReachable: Bool {
        return isReachable
    }
}
