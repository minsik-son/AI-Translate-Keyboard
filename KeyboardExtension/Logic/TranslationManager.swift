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
    private var session: URLSession { SharedNetworkSession.shared }
    private var debounceWorkItem: DispatchWorkItem?
    private var lastTranslatedText: String = ""
    private var retryCount = 0
    private let maxRetries = 1
    private var currentGeneration: Int = 0

    private var sourceLang: String = "ko"
    private var targetLang: String = "en"

    func setLanguages(source: String, target: String) {
        self.sourceLang = source
        self.targetLang = target
    }

    func requestTranslation(text: String) {
        debounceWorkItem?.cancel()

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != lastTranslatedText else { return }

        // Check cache first (instant, no debounce needed)
        if let cached = cache.get(text: trimmed, source: sourceLang, target: targetLang) {
            currentGeneration += 1
            lastTranslatedText = trimmed
            delegate?.translationManager(self, didTranslate: cached, from: sourceLang, to: targetLang)
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.performTranslation(text: trimmed)
        }
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Limits.debounceDuration, execute: workItem)
    }

    func cancelPending() {
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
        currentGeneration += 1
    }

    private func performTranslation(text: String) {
        delegate?.translationManagerDidStartTranslating(self)
        currentGeneration += 1
        retryCount = 0
        executeRequest(text: text, generation: currentGeneration)
    }

    private func executeRequest(text: String, generation: Int) {
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
                self?.handleResponse(text: text, generation: generation, data: data, response: response, error: error)
            }
        }
        task.resume()
    }

    private func handleResponse(text: String, generation: Int, data: Data?, response: URLResponse?, error: Error?) {
        // Discard stale responses — only process the latest generation
        guard generation == currentGeneration else { return }

        if let error = error {
            let nsError = error as NSError
            if nsError.code == NSURLErrorTimedOut {
                if retryCount < maxRetries {
                    retryCount += 1
                    executeRequest(text: text, generation: generation)
                    return
                }
                delegate?.translationManager(self, didFailWithError: .timeout)
            } else if nsError.code == NSURLErrorNotConnectedToInternet {
                delegate?.translationManager(self, didFailWithError: .offline)
            } else {
                if retryCount < maxRetries {
                    retryCount += 1
                    executeRequest(text: text, generation: generation)
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

        cache.set(text: text, source: sourceLang, target: targetLang, translatedText: translatedText)
        lastTranslatedText = text

        // Log to session (stats는 세션 종료 시 CompositionSessionManager에서 처리)
        CompositionSessionManager.shared.recordAPICall(sourceText: text, resultText: translatedText)

        delegate?.translationManager(self, didTranslate: translatedText, from: sourceLang, to: targetLang)
    }
}
