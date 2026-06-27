import Foundation

enum ConsoleDockSensitiveTextRedactor {
    static func redacted(_ text: String) -> String {
        var result = text
        result = replacing(
            result,
            pattern: #"\bAuthorization\s*[:=]\s*[^\r\n]+"#,
            template: "Authorization: <redacted>"
        )
        result = replacing(
            result,
            pattern: #"\b(Set-Cookie|Cookie)\s*:\s*[^\r\n]+"#,
            template: "$1: <redacted>"
        )
        result = replacing(
            result,
            pattern:
                #"("?(?:password|passwd|token|id[_-]?token|auth[_-]?token|session[_-]?token|csrf[_-]?token|access[_-]?token|refresh[_-]?token|x[_-]?api[_-]?key|api[_-]?key|client[_-]?secret|key|secret)"?\s*[:=]\s*")([^"]+)(")"#,
            template: "$1<redacted>$3"
        )
        result = replacing(
            result,
            pattern:
                #"\b(password|passwd|token|id[_-]?token|auth[_-]?token|session[_-]?token|csrf[_-]?token|access[_-]?token|refresh[_-]?token|x[_-]?api[_-]?key|api[_-]?key|client[_-]?secret|key|secret)\b\s*[:=]\s*[^\s,;&]+"#,
            template: "$1=<redacted>"
        )
        result = replacing(
            result,
            pattern: #"\bBearer\s+[^\s,;&]+"#,
            template: "Bearer <redacted>"
        )
        return result
    }

    static func redactedValue(key: String, value: String) -> String {
        if isSensitiveName(key) {
            return "<redacted>"
        }
        return redacted(value)
    }

    static func isSensitiveName(_ name: String) -> Bool {
        let compactName =
            name
            .lowercased()
            .unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) }
            .map(String.init)
            .joined()
        let sensitiveIndicators = [
            "password",
            "passwd",
            "token",
            "secret",
            "apikey",
            "xapikey",
            "authorization",
            "credential",
            "bearer",
            "clientsecret",
            "privatekey",
            "accesskey",
            "sessionid",
            "sessiontoken",
            "idtoken",
            "authtoken",
            "csrftoken",
            "refreshtoken"
        ]
        return sensitiveIndicators.contains { compactName.contains($0) }
    }

    private static func replacing(_ text: String, pattern: String, template: String) -> String {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return text
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return expression.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: template)
    }
}
