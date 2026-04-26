import Foundation

enum InfopostExternalRouteDecision: Equatable {
    case allow
    case cancel
    case openExternally(URL)
}

struct InfopostExternalURLRouter {
    func decision(for requestURL: URL?) -> InfopostExternalRouteDecision {
        guard let requestURL else {
            return .allow
        }

        guard requestURL.scheme?.lowercased() == "sotka",
              requestURL.host?.lowercased() == "youtube" else {
            return .allow
        }

        guard let youtubeURL = extractYouTubeURL(from: requestURL) else {
            return .cancel
        }

        return .openExternally(youtubeURL)
    }
}

private extension InfopostExternalURLRouter {
    func extractYouTubeURL(from requestURL: URL) -> URL? {
        guard let components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false),
              let rawTargetURL = components.queryItems?.first(where: { $0.name == "url" })?.value,
              let decodedTargetURL = rawTargetURL.removingPercentEncoding,
              let targetURL = URL(string: decodedTargetURL),
              targetURL.scheme?.lowercased() == "https" else {
            return nil
        }

        let normalizedHost = normalize(host: targetURL.host)
        guard normalizedHost == "youtube.com" || normalizedHost.hasSuffix(".youtube.com") || normalizedHost == "youtu.be" else {
            return nil
        }

        return targetURL
    }

    func normalize(host: String?) -> String {
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
}
