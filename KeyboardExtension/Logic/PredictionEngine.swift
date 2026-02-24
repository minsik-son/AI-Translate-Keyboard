import Foundation

final class PredictionEngine {
    private var trigrams: [String: [(String, Int)]] = [:]
    private var bigrams: [String: [(String, Int)]] = [:]
    private var unigrams: [(String, Int)] = []
    private var loadedLanguage: String?

    func loadModel(for language: String) {
        guard language != loadedLanguage else { return }

        let fileName = "ngram_\(language)"
        guard let url = Bundle(for: type(of: self)).url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            trigrams = [:]
            bigrams = [:]
            unigrams = []
            loadedLanguage = nil
            return
        }

        if let trigramData = json["trigrams"] as? [String: [[Any]]] {
            trigrams = trigramData.mapValues { entries in
                entries.compactMap { entry in
                    guard entry.count >= 2,
                          let word = entry[0] as? String,
                          let freq = entry[1] as? Int else { return nil }
                    return (word, freq)
                }
            }
        } else {
            trigrams = [:]
        }

        if let bigramData = json["bigrams"] as? [String: [[Any]]] {
            bigrams = bigramData.mapValues { entries in
                entries.compactMap { entry in
                    guard entry.count >= 2,
                          let word = entry[0] as? String,
                          let freq = entry[1] as? Int else { return nil }
                    return (word, freq)
                }
            }
        } else {
            bigrams = [:]
        }

        if let unigramData = json["unigrams"] as? [[Any]] {
            unigrams = unigramData.compactMap { entry in
                guard entry.count >= 2,
                      let word = entry[0] as? String,
                      let freq = entry[1] as? Int else { return nil }
                return (word, freq)
            }
        } else {
            unigrams = []
        }

        loadedLanguage = language
    }

    func predict(context: [String], limit: Int = 3) -> [String] {
        var scored: [String: Double] = [:]

        let normalizedContext = context.map { $0.lowercased() }

        // Trigram lookup: last 2 words
        if normalizedContext.count >= 2 {
            let key = normalizedContext.suffix(2).joined(separator: " ")
            if let matches = trigrams[key] {
                for (word, freq) in matches {
                    scored[word, default: 0] += Double(freq) * 1.0
                }
            }
        }

        // Bigram fallback: last 1 word
        if let lastWord = normalizedContext.last {
            if let matches = bigrams[lastWord] {
                for (word, freq) in matches {
                    scored[word, default: 0] += Double(freq) * 0.4
                }
            }
        }

        // Unigram fallback
        for (word, freq) in unigrams {
            scored[word, default: 0] += Double(freq) * 0.16
        }

        let sorted = scored.sorted { $0.value > $1.value }
        return Array(sorted.prefix(limit).map { $0.key })
    }
}
