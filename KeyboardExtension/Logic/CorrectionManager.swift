import UIKit

protocol CorrectionManagerDelegate: AnyObject {
    func correctionManager(_ manager: CorrectionManager, didCorrect text: String, language: String)
    func correctionManager(_ manager: CorrectionManager, didFailWithError error: TranslationError)
    func correctionManagerDidStartCorrecting(_ manager: CorrectionManager)
}

class CorrectionManager {

    weak var delegate: CorrectionManagerDelegate?

    private let cache = TranslationCache.shared
    private let session: URLSession
    private var debounceWorkItem: DispatchWorkItem?
    private var lastCorrectedText: String = ""
    private var retryCount = 0
    private let maxRetries = 1

    private var languageCode: String = "ko"

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = AppConstants.API.timeout
        config.timeoutIntervalForResource = AppConstants.API.timeout
        self.session = URLSession(configuration: config)
    }

    func setLanguage(_ code: String) {
        self.languageCode = code
    }

    func requestCorrection(text: String) {
        debounceWorkItem?.cancel()

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != lastCorrectedText else { return }

        if let cached = cache.get(text: trimmed, source: "correct", target: languageCode) {
            lastCorrectedText = trimmed
            delegate?.correctionManager(self, didCorrect: cached, language: languageCode)
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.performCorrection(text: trimmed)
        }
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Limits.debounceDuration, execute: workItem)
    }

    func cancelPending() {
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
    }

    func reset() {
        lastCorrectedText = ""
        cancelPending()
    }

    private func performCorrection(text: String) {
        delegate?.correctionManagerDidStartCorrecting(self)
        retryCount = 0
        executeRequest(text: text)
    }

    private func executeRequest(text: String) {
        let urlString = AppConstants.API.baseURL + AppConstants.API.correctEndpoint
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let tier = SubscriptionStatus.shared.currentTier.rawValue

        let body: [String: Any] = [
            "text": text,
            "language": languageCode,
            "tier": tier,
            "deviceId": deviceId
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.handleResponse(text: text, data: data, response: response, error: error)
            }
        }
        task.resume()
    }

    private func handleResponse(text: String, data: Data?, response: URLResponse?, error: Error?) {
        if let error = error {
            let nsError = error as NSError
            if nsError.code == NSURLErrorTimedOut {
                if retryCount < maxRetries {
                    retryCount += 1
                    executeRequest(text: text)
                    return
                }
                delegate?.correctionManager(self, didFailWithError: .timeout)
            } else if nsError.code == NSURLErrorNotConnectedToInternet {
                delegate?.correctionManager(self, didFailWithError: .offline)
            } else {
                if retryCount < maxRetries {
                    retryCount += 1
                    executeRequest(text: text)
                    return
                }
                delegate?.correctionManager(self, didFailWithError: .networkError(error))
            }
            return
        }

        guard let httpResponse = response as? HTTPURLResponse,
              let data = data else {
            delegate?.correctionManager(self, didFailWithError: .invalidResponse)
            return
        }

        if httpResponse.statusCode == 429 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let retryAfter = json["retryAfter"] as? Int {
                delegate?.correctionManager(self, didFailWithError: .rateLimited(retryAfter))
            }
            return
        }

        guard httpResponse.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            delegate?.correctionManager(self, didFailWithError: .serverError(httpResponse.statusCode, errorMsg))
            return
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let correctedText = json["correctedText"] as? String else {
            delegate?.correctionManager(self, didFailWithError: .invalidResponse)
            return
        }

        cache.set(text: text, source: "correct", target: languageCode, translatedText: correctedText)
        lastCorrectedText = text

        delegate?.correctionManager(self, didCorrect: correctedText, language: languageCode)
    }
}
