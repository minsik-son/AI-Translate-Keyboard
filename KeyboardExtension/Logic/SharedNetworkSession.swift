import Foundation

final class SharedNetworkSession {
    static let shared: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConstants.API.timeout
        config.timeoutIntervalForResource = AppConstants.API.timeout
        config.httpShouldUsePipelining = true
        config.urlCache = nil
        return URLSession(configuration: config)
    }()
}
