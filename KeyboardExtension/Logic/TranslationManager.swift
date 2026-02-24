import UIKit

protocol TranslationManagerDelegate: AnyObject {
    func translationManager(_ manager: TranslationManager, didTranslate text: String, from source: String, to target: String)
    func translationManager(_ manager: TranslationManager, didFailWithError error: TranslationError)
    func translationManagerDidStartTranslating(_ manager: TranslationManager)
}

enum TranslationError: Error {
    case networkError(Error)
    case serverError(Int, String)
    case rateLimited(Int)
    case offline
    case timeout
    case invalidResponse
}

class TranslationManager {

    weak var delegate: TranslationManagerDelegate?

    private let cache = TranslationCache.shared
    private let session: URLSession
    private var debounceWorkItem: DispatchWorkItem?
    private var lastTranslatedText: String = ""
    private var retryCount = 0
    private let maxRetries = 1

    private var sourceLang: String = "ko"
    private var targetLang: String = "en"

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = AppConstants.API.timeout
        config.timeoutIntervalForResource = AppConstants.API.timeout
        self.session = URLSession(configuration: config)
    }

    func setLanguages(source: String, target: String) {
        self.sourceLang = source
        self.targetLang = target
    }

    func requestTranslation(text: String) {
        // Cancel previous debounce
        debounceWorkItem?.cancel()

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Skip if same text
        guard !trimmed.isEmpty, trimmed != lastTranslatedText else { return }

        // Check cache first
        if let cached = cache.get(text: trimmed, source: sourceLang, target: targetLang) {
            lastTranslatedText = trimmed
            delegate?.translationManager(self, didTranslate: cached, from: sourceLang, to: targetLang)
            return
        }

        // Debounce
        let workItem = DispatchWorkItem { [weak self] in
            self?.performTranslation(text: trimmed)
        }
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Limits.debounceDuration, execute: workItem)
    }

    func cancelPending() {
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
    }

    private func performTranslation(text: String) {
        delegate?.translationManagerDidStartTranslating(self)
        retryCount = 0
        executeRequest(text: text)
    }

    private func executeRequest(text: String) {
        let urlString = AppConstants.API.baseURL + AppConstants.API.translateEndpoint
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let tier = SubscriptionStatus.shared.currentTier.rawValue

        let body: [String: Any] = [
            "text": text,
            "sourceLang": sourceLang,
            "targetLang": targetLang,
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
                delegate?.translationManager(self, didFailWithError: .timeout)
            } else if nsError.code == NSURLErrorNotConnectedToInternet {
                delegate?.translationManager(self, didFailWithError: .offline)
            } else {
                if retryCount < maxRetries {
                    retryCount += 1
                    executeRequest(text: text)
                    return
                }
                delegate?.translationManager(self, didFailWithError: .networkError(error))
            }
            return
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            delegate?.translationManager(self, didFailWithError: .invalidResponse)
            return
        }

        guard let data = data else {
            delegate?.translationManager(self, didFailWithError: .invalidResponse)
            return
        }

        if httpResponse.statusCode == 429 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let retryAfter = json["retryAfter"] as? Int {
                delegate?.translationManager(self, didFailWithError: .rateLimited(retryAfter))
            }
            return
        }

        guard httpResponse.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            delegate?.translationManager(self, didFailWithError: .serverError(httpResponse.statusCode, errorMsg))
            return
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let translatedText = json["translatedText"] as? String else {
            delegate?.translationManager(self, didFailWithError: .invalidResponse)
            return
        }

        // Cache the result
        cache.set(text: text, source: sourceLang, target: targetLang, translatedText: translatedText)
        lastTranslatedText = text

        delegate?.translationManager(self, didTranslate: translatedText, from: sourceLang, to: targetLang)
    }
}
