import Foundation
import UIKit

public final class FeedbackService {
    public static let shared = FeedbackService()
    private init() {}

    // MARK: - Public API
    @discardableResult
    public func sendFeedback(
        title: String,
        description: String,
        images: [UIImage],
        to overrideToEmail: String? = nil
    ) async -> Bool {
        guard let apiKey = Self.loadResendApiKey() else { return false }

        var toEmail = overrideToEmail
            ?? (Bundle.main.object(forInfoDictionaryKey: "FEEDBACK_TO_EMAIL") as? String)
            ?? UserDefaults.standard.string(forKey: "FEEDBACK_TO_EMAIL")
            ?? ProcessInfo.processInfo.environment["FEEDBACK_TO_EMAIL"]
            ?? "Hope.adebayo02@gmail.com"
        toEmail = toEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        var fromEmail = (Bundle.main.object(forInfoDictionaryKey: "RESEND_FROM_EMAIL") as? String)
            ?? UserDefaults.standard.string(forKey: "RESEND_FROM_EMAIL")
            ?? ProcessInfo.processInfo.environment["RESEND_FROM_EMAIL"]
            ?? "onboarding@resend.dev"

        let fromName = (Bundle.main.object(forInfoDictionaryKey: "RESEND_FROM_NAME") as? String)
            ?? UserDefaults.standard.string(forKey: "RESEND_FROM_NAME")
            ?? ProcessInfo.processInfo.environment["RESEND_FROM_NAME"]
            ?? "Bible App Feedback"

        // If the configured from address is a free mailbox (e.g., gmail, yahoo), force the
        // verified Resend sender to avoid 403 or domain verification errors. Use Reply-To so
        // responses go to the intended mailbox.
        let lowerFrom = fromEmail.lowercased()
        let isFreeMailbox = lowerFrom.contains("@gmail.") || lowerFrom.contains("@yahoo.") || lowerFrom.contains("@outlook.") || lowerFrom.contains("@hotmail.") || lowerFrom.contains("@icloud.")
        var replyTo: String? = nil
        if isFreeMailbox {
            replyTo = fromEmail
            fromEmail = "onboarding@resend.dev"
        }

        struct Attachment: Codable {
            let filename: String
            let content: String
        }

        let attachments: [Attachment] = images.enumerated().compactMap { index, image in
            guard let data = image.jpegData(compressionQuality: 0.7) else { return nil }
            return Attachment(filename: "screenshot_\(index + 1).jpg", content: data.base64EncodedString())
        }

        let html = Self.composeHTML(title: title, description: description, imageCount: attachments.count)

        struct EmailRequest: Codable {
            let from: String
            let to: [String]
            let subject: String
            let html: String
            let attachments: [Attachment]?
            let reply_to: String?
        }

        let reqBody = EmailRequest(
            from: "\(fromName) <\(fromEmail)>",
            to: [toEmail],
            subject: "Bible App Feedback: \(title)",
            html: html,
            attachments: attachments.isEmpty ? nil : attachments,
            reply_to: replyTo
        )

        guard let bodyData = try? JSONEncoder().encode(reqBody) else { return false }

        var request = URLRequest(url: URL(string: "https://api.resend.com/emails")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = bodyData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                if (200..<300).contains(http.statusCode) {
                    _ = try? JSONSerialization.jsonObject(with: data)
                    return true
                } else {
                    let body = String(data: data, encoding: .utf8) ?? "<no body>"
                    print("RESEND_ERROR status=\(http.statusCode) body=\(body)")
                    return false
                }
            }
            return false
        } catch {
            print("RESEND_ERROR network=\(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Helpers
    private static func composeHTML(title: String, description: String, imageCount: Int) -> String {
        let escaped = description
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        let pre = "<pre style=\"font-family: -apple-system, Roboto, Helvetica, Arial, sans-serif; white-space: pre-wrap;\">\(escaped)</pre>"
        let imgNote = imageCount > 0 ? "<p>\(imageCount) image attachment(s) included.</p>" : ""
        return """
        <div>
          <h2>📮 New Feedback</h2>
          <p style=\"margin: 0 0 8px;\"><strong>Title:</strong> \(title)</p>
          \(pre)
          \(imgNote)
        </div>
        """
    }

    private static func loadResendApiKey() -> String? {
        func sanitize(_ raw: String?) -> String? {
            guard var s = raw?.trimmingCharacters(in: .whitespacesAndNewlines), s.isEmpty == false else { return nil }
            if s.hasPrefix("\"") && s.hasSuffix("\"") { s = String(s.dropFirst().dropLast()) }
            if s.hasPrefix("'") && s.hasSuffix("'") { s = String(s.dropFirst().dropLast()) }
            return s.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let v = sanitize(Bundle.main.object(forInfoDictionaryKey: "RESEND_API_KEY") as? String) { return v }
        if let v = sanitize(UserDefaults.standard.string(forKey: "RESEND_API_KEY")) { return v }
        if let v = sanitize(ProcessInfo.processInfo.environment["RESEND_API_KEY"]) { return v }

        // Load from bundled env file similar to ESV/NLT
        guard let url = Bundle.main.url(forResource: "RESEND", withExtension: "env") else { return nil }
        guard let raw = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let lines = raw.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        for line in lines {
            if line.isEmpty { continue }
            if let eq = line.firstIndex(of: "=") {
                let key = String(line[..<eq]).trimmingCharacters(in: .whitespacesAndNewlines)
                var value = String(line[line.index(after: eq)...]).trimmingCharacters(in: .whitespacesAndNewlines)
                if value.hasPrefix("\"") && value.hasSuffix("\"") { value = String(value.dropFirst().dropLast()) }
                if value.hasPrefix("'") && value.hasSuffix("'") { value = String(value.dropFirst().dropLast()) }
                let normalizedKey = key.replacingOccurrences(of: "\\s+", with: "_", options: .regularExpression).uppercased()
                if normalizedKey == "RESEND_API_KEY" && value.isEmpty == false {
                    UserDefaults.standard.set(value, forKey: "RESEND_API_KEY")
                    return value
                }
                if normalizedKey == "FEEDBACK_TO_EMAIL" && value.isEmpty == false {
                    UserDefaults.standard.set(value, forKey: "FEEDBACK_TO_EMAIL")
                }
                if normalizedKey == "RESEND_FROM_EMAIL" && value.isEmpty == false {
                    UserDefaults.standard.set(value, forKey: "RESEND_FROM_EMAIL")
                }
                if normalizedKey == "RESEND_FROM_NAME" && value.isEmpty == false {
                    UserDefaults.standard.set(value, forKey: "RESEND_FROM_NAME")
                }
            }
        }
        return UserDefaults.standard.string(forKey: "RESEND_API_KEY")
    }
}


