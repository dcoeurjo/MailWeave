import Foundation
import AppKit

class EmailService {
 
    func sendEmails(
        to recipients: [Recipient],
        subject: String,
        cc: String,
        replyTo: String,
        completion: @escaping ([Bool]) -> Void,
        progress: @escaping (Int, Int) -> Void,
        composeOnly: Bool = true,
        attachPath: String? = nil,
        isCancelled: @escaping () -> Bool
    ) {

        DispatchQueue.global(qos: .userInitiated).async {

            var results: [Bool] = []

            let total = recipients.count

            for (index, recipient) in recipients.enumerated() {
                if isCancelled() {
                    break
                }
                let resolvedSubject = self.personalizeMessage(
                    subject,
                    fields: recipient.fields
                )

                let resolvedCc = self.personalizeMessage(
                    cc,
                    fields: recipient.fields
                )

                let body = self.personalizeMessage(
                    recipient.message,
                    fields: recipient.fields
                )

                let path = self.personalizeMessage(
                    recipient.attachment,
                    fields: recipient.fields
                )

                let success: Bool

                if composeOnly {

                    success = self.createEmailInMailApp(
                        to: recipient.email,
                        cc: resolvedCc,
                        replyTo: replyTo,
                        subject: resolvedSubject,
                        body: body
                    )

                } else {

                    success = self.createAndSendEmailInMailApp(
                        to: recipient.email,
                        cc: resolvedCc,
                        replyTo: replyTo,
                        subject: resolvedSubject,
                        body: body,
                        attachmentPath: path
                    )
                }

                results.append(success)

                // Mise à jour de la progression sur le thread principal
                let current = index + 1

                DispatchQueue.main.async {
                    progress(current, total)
                }

                // Petite pause entre deux mails
                Thread.sleep(forTimeInterval: 0.5)
            }

            // Fin du traitement
            DispatchQueue.main.async {
                completion(results)
            }
        }
    }

    
    func personalizeMessage(_ message: String, fields: [String: String]) -> String {
        let normalizedFields = normalizeFieldMap(fields)
        return replacePlaceholders(in: message, fields: normalizedFields)
    }
    
    private func replacePlaceholders(in message: String, fields: [String: String]) -> String {
        var result = message
        var searchRange = result.startIndex..<result.endIndex
        
        while let openRange = result.range(of: "{{", range: searchRange) {
            guard let closeRange = result.range(of: "}}", range: openRange.upperBound..<result.endIndex) else {
                break
            }
            let rawKey = String(result[openRange.upperBound..<closeRange.lowerBound])
            let key = normalizePlaceholderKey(rawKey)
            if let replacement = fields[key] {
                result.replaceSubrange(openRange.lowerBound..<closeRange.upperBound, with: replacement)
                searchRange = openRange.lowerBound..<result.endIndex
            } else {
                searchRange = closeRange.upperBound..<result.endIndex
            }
        }
        
        return result
    }
    
    private func normalizeFieldMap(_ fields: [String: String]) -> [String: String] {
        var normalized: [String: String] = [:]
        for (key, value) in fields {
            let normalizedKey = normalizePlaceholderKey(key)
            if normalized[normalizedKey] == nil {
                normalized[normalizedKey] = value
            }
        }
        return normalized
    }
    
    private func normalizePlaceholderKey(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let withoutBom = trimmed.replacingOccurrences(of: "\u{FEFF}", with: "")
        let collapsed = withoutBom.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        let withoutBraces = stripPlaceholderBraces(from: collapsed)
        return sanitizeKey(withoutBraces)
    }
    
    private func sanitizeKey(_ key: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(.init(charactersIn: " _-"))
        let filtered = String(key.unicodeScalars.filter { allowed.contains($0) })
        let collapsed = filtered.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        return collapsed.lowercased()
    }
    
    private func stripPlaceholderBraces(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("{{"), trimmed.hasSuffix("}}") else { return trimmed }
        let start = trimmed.index(trimmed.startIndex, offsetBy: 2)
        let end = trimmed.index(trimmed.endIndex, offsetBy: -2)
        let inner = String(trimmed[start..<end])
        return inner.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func createEmailInMailApp(to: String, cc: String, replyTo: String, subject: String, body: String) -> Bool {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = to
        
        var queryItems: [URLQueryItem] = []
        if !subject.isEmpty {
            queryItems.append(URLQueryItem(name: "subject", value: subject))
        }
        let normalizedReplyTo = replyTo.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalizedReplyTo.isEmpty {
            queryItems.append(URLQueryItem(name: "reply-to", value: normalizedReplyTo))
        }
        if !body.isEmpty {
            queryItems.append(URLQueryItem(name: "body", value: body))
        }
        let normalizedCc = cc
            .replacingOccurrences(of: ";", with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ",")
        if !normalizedCc.isEmpty {
            queryItems.append(URLQueryItem(name: "cc", value: normalizedCc))
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        guard let mailtoURL = components.url else {
            return false
        }
        
        // Open the URL in Mail.app (must be called on main thread)
        _ = DispatchQueue.main.sync {
            NSWorkspace.shared.open(mailtoURL)
        }
        
        return true
    }
  
  
  private func createAndSendEmailInMailApp(to: String, cc: String, replyTo: String, subject: String,
                                           body: String, attachmentPath: String?) -> Bool {
      let toList = to
          .replacingOccurrences(of: ";", with: ",")
          .split(separator: ",")
          .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
          .filter { !$0.isEmpty }

      let ccList = cc
          .replacingOccurrences(of: ";", with: ",")
          .split(separator: ",")
          .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
          .filter { !$0.isEmpty }

      guard !toList.isEmpty else { return false }

      func esc(_ s: String) -> String {
          s.replacingOccurrences(of: "\\", with: "\\\\")
           .replacingOccurrences(of: "\"", with: "\\\"")
      }

      // Convertit le corps Markdown en RTF hexadécimal
   
    
      var script = """
      tell application "Mail"
          set newMessage to make new outgoing message with properties {subject:"\(esc(subject))", visible:true}
          tell newMessage
        set content to "\(esc(body))"
      """

      if let path = attachmentPath  {
        script += """

        tell content of newMessage
            make new attachment with properties {file name:"\(path)"} at after the last paragraph
        end tell
        """
    }
    
      for recipient in toList {
          script += """

              make new to recipient at end of to recipients with properties {address:"\(esc(recipient))"}
          """
      }

      for recipient in ccList {
          script += """

              make new cc recipient at end of cc recipients with properties {address:"\(esc(recipient))"}
          """
      }

    

      script += """

          end tell
          delay 0.3
          send newMessage
      end tell
      
      """

      var executionError: NSDictionary?
      guard let appleScript = NSAppleScript(source: script) else { return false }

      appleScript.executeAndReturnError(&executionError)
     
      if let error = executionError {
          print("AppleScript error: \(error)")
      }

      return executionError == nil
  }
}

