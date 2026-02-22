import Foundation

class SpreadsheetParser {
    struct ParseResult {
        let headers: [String]
        let rows: [[String: String]]
        let errorMessage: String?
    }
    
    func parseCSV(from url: URL, delimiter: Character) -> ParseResult {
        var parsedHeaders: [String] = []
        var rows: [[String: String]] = []
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            var lines = splitRecords(from: content)
            if lines.count == 1, content.rangeOfCharacter(from: .newlines) != nil {
                lines = content.components(separatedBy: .newlines)
            }
            let resolvedDelimiter = resolveDelimiter(preferred: delimiter, in: lines)
            
            guard let headerLine = lines.first else {
                return ParseResult(headers: [], rows: [], errorMessage: "The CSV file is empty")
            }
            
            let headers = parseCSVLine(headerLine, delimiter: resolvedDelimiter)
            parsedHeaders = headers.map { normalizeHeader($0) }.filter { !$0.isEmpty }
            
            let dataLines = lines.dropFirst()
            
            for line in dataLines {
                // Skip empty lines
                if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    continue
                }
                
                let components = parseCSVLine(line, delimiter: resolvedDelimiter)
                let fields = buildFieldMap(headers: headers, components: components)
                if fields.isEmpty {
                    continue
                }
                rows.append(fields)
            }
        } catch {
            return ParseResult(headers: parsedHeaders, rows: rows, errorMessage: "Error reading CSV file: \(error.localizedDescription)")
        }
        
        return ParseResult(headers: parsedHeaders, rows: rows, errorMessage: nil)
    }
    
    private func parseCSVLine(_ line: String, delimiter: Character) -> [String] {
        var components: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        let characters = Array(line)
        var index = 0
        
        while index < characters.count {
            let char = characters[index]
            if char == "\"" {
                if insideQuotes, index + 1 < characters.count, characters[index + 1] == "\"" {
                    currentField.append("\"")
                    index += 2
                    continue
                }
                insideQuotes.toggle()
                index += 1
                continue
            }
            
            if char == delimiter && !insideQuotes {
                components.append(currentField)
                currentField = ""
                index += 1
                continue
            }
            
            currentField.append(char)
            index += 1
        }
        
        // Add the last field
        components.append(currentField)
        
        return components
    }
    
    private func componentValue(at index: Int, in components: [String]) -> String {
        guard index < components.count else { return "" }
        return components[index].trimmingCharacters(in: .whitespaces)
    }
    
    private func normalizeHeader(_ header: String) -> String {
        let trimmed = header.trimmingCharacters(in: .whitespacesAndNewlines)
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
    
    private func buildFieldMap(headers: [String], components: [String]) -> [String: String] {
        var fields: [String: String] = [:]
        for (index, header) in headers.enumerated() {
            let key = normalizeHeader(header)
            guard !key.isEmpty else { continue }
            let value = componentValue(at: index, in: components)
            fields[key] = value
        }
        return fields
    }
    
    private func resolveDelimiter(preferred: Character, in lines: [String]) -> Character {
        guard let firstNonEmpty = lines.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            return preferred
        }
        
        if firstNonEmpty.contains(preferred) {
            return preferred
        }
        
        let candidates: [Character] = [";", ",", "\t", "|"]
        var bestDelimiter = preferred
        var bestCount = 0
        
        for candidate in candidates {
            let count = firstNonEmpty.filter { $0 == candidate }.count
            if count > bestCount {
                bestCount = count
                bestDelimiter = candidate
            }
        }
        
        return bestCount > 0 ? bestDelimiter : preferred
    }
    
    private func splitRecords(from content: String) -> [String] {
        var records: [String] = []
        var currentRecord = ""
        var insideQuotes = false
        let characters = Array(content)
        var index = 0
        
        while index < characters.count {
            let char = characters[index]
            if char == "\"" {
                if insideQuotes, index + 1 < characters.count, characters[index + 1] == "\"" {
                    currentRecord.append(char)
                    currentRecord.append(characters[index + 1])
                    index += 2
                    continue
                }
                insideQuotes.toggle()
                currentRecord.append(char)
                index += 1
                continue
            }
            
            if (char == "\r" || char == "\n") && !insideQuotes {
                records.append(currentRecord)
                currentRecord = ""
                if char == "\r", index + 1 < characters.count, characters[index + 1] == "\n" {
                    index += 2
                    continue
                }
                index += 1
                continue
            }
            
            currentRecord.append(char)
            index += 1
        }
        
        if !currentRecord.isEmpty {
            records.append(currentRecord)
        }
        
        return records
    }
}
