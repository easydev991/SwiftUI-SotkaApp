import Foundation

struct YouTubeLinkNormalizer {
    func normalizedWatchURL(from rawURL: String) -> URL? {
        let sourceURL = normalizeSourceURL(rawURL)
        guard let url = URL(string: sourceURL) else {
            return nil
        }

        guard let videoID = extractVideoID(from: url) else {
            return nil
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.youtube.com"
        components.path = "/watch"
        components.queryItems = [URLQueryItem(name: "v", value: videoID)]

        return components.url
    }
}

private extension YouTubeLinkNormalizer {
    func normalizeSourceURL(_ rawURL: String) -> String {
        let trimmedURL = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedURL.hasPrefix("//") {
            return "https:\(trimmedURL)"
        }
        return trimmedURL
    }

    func extractVideoID(from url: URL) -> String? {
        let host = normalizedHost(from: url.host)
        guard isYouTubeHost(host) else {
            return nil
        }

        if host == "youtu.be" {
            return firstPathComponent(in: url.path)
        }

        let pathComponents = url.pathComponents

        if let embedIndex = pathComponents.firstIndex(of: "embed"), embedIndex + 1 < pathComponents.count {
            return sanitizeVideoID(pathComponents[embedIndex + 1])
        }

        if let shortsIndex = pathComponents.firstIndex(of: "shorts"), shortsIndex + 1 < pathComponents.count {
            return sanitizeVideoID(pathComponents[shortsIndex + 1])
        }

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let videoID = components.queryItems?.first(where: { $0.name == "v" })?.value {
            return sanitizeVideoID(videoID)
        }

        if pathComponents.count == 2 {
            return sanitizeVideoID(pathComponents[1])
        }

        return nil
    }

    func normalizedHost(from host: String?) -> String {
        guard let host else { return "" }

        let lowercasedHost = host.lowercased()
        if lowercasedHost.hasPrefix("www.") {
            return String(lowercasedHost.dropFirst(4))
        }
        if lowercasedHost.hasPrefix("m.") {
            return String(lowercasedHost.dropFirst(2))
        }
        return lowercasedHost
    }

    func isYouTubeHost(_ host: String) -> Bool {
        host == "youtube.com" || host.hasSuffix(".youtube.com") || host == "youtu.be"
    }

    func firstPathComponent(in path: String) -> String? {
        let trimmedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !trimmedPath.isEmpty else { return nil }
        return sanitizeVideoID(trimmedPath.components(separatedBy: "/").first ?? "")
    }

    func sanitizeVideoID(_ rawID: String) -> String? {
        let trimmedID = rawID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedID.isEmpty else { return nil }

        let separators = ["?", "&", "#", "/"]
        let cleanID = separators.reduce(trimmedID) { partialResult, separator in
            partialResult.components(separatedBy: separator).first ?? partialResult
        }

        return cleanID.isEmpty ? nil : cleanID
    }
}
