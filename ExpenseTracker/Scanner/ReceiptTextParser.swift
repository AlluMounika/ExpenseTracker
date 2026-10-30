//
//  ReceiptTextParser.swift
//  ExpenseTracker
//

import Foundation

struct ReceiptDetails: Equatable {
    var restaurantName: String?
    var date: Date?
    var amount: Double?
}

/// Picks the restaurant name, date and total out of recognized receipt lines.
/// Receipts vary a lot, so these are best-effort guesses the user should be able to correct.
enum ReceiptTextParser {
    static func parse(lines: [String]) -> ReceiptDetails {
        let lines = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return ReceiptDetails(
            restaurantName: restaurantName(in: lines),
            date: date(in: lines),
            amount: totalAmount(in: lines)
        )
    }

    // MARK: - Restaurant name

    private static let headerWordsToSkip = [
        "receipt", "welcome", "invoice", "order", "table", "server", "guest", "check", "tel", "phone", "www", "http"
    ]

    /// The name is usually the first real line of text at the top of the receipt.
    private static func restaurantName(in lines: [String]) -> String? {
        lines.prefix(6).first { line in
            let lowercased = line.lowercased()
            let letterCount = line.filter(\.isLetter).count
            let digitCount = line.filter(\.isNumber).count

            return letterCount >= 3
                && digitCount <= letterCount / 2
                && !headerWordsToSkip.contains { lowercased.contains($0) }
                && amounts(in: line).isEmpty
        }
    }

    // MARK: - Date

    private static let dateDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)

    private static let monthNames = [
        "jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"
    ]

    private static func date(in lines: [String]) -> Date? {
        guard let dateDetector else { return nil }

        for line in lines {
            let range = NSRange(line.startIndex..., in: line)
            for match in dateDetector.matches(in: line, range: range) {
                guard let date = match.date,
                      let matchRange = Range(match.range, in: line) else { continue }

                // The detector also matches a bare time like "12:30 PM" as today's date,
                // so only accept matches that actually contain a calendar date.
                let matched = line[matchRange].lowercased()
                let hasCalendarDate = matched.contains("/")
                    || matched.contains("-")
                    || matched.contains(".")
                    || monthNames.contains { matched.contains($0) }
                if hasCalendarDate {
                    return date
                }
            }
        }
        return nil
    }

    // MARK: - Amount

    private static let totalKeywords = ["total", "amount due", "balance due", "amount paid"]
    private static let nonTotalKeywords = ["subtotal", "sub total", "sub-total", "total tax", "total items"]

    /// Prefers the amount on a "Total" line (or the line just below it, when the
    /// amount is printed separately). Falls back to the largest amount on the receipt.
    private static func totalAmount(in lines: [String]) -> Double? {
        var totalCandidates: [Double] = []

        for (index, line) in lines.enumerated() {
            let lowercased = line.lowercased()
            guard totalKeywords.contains(where: { lowercased.contains($0) }),
                  !nonTotalKeywords.contains(where: { lowercased.contains($0) }) else { continue }

            let onLine = amounts(in: line)
            if !onLine.isEmpty {
                totalCandidates.append(contentsOf: onLine)
            } else if index + 1 < lines.count {
                totalCandidates.append(contentsOf: amounts(in: lines[index + 1]))
            }
        }

        // Take the largest so a "Total with tip" line wins over the pre-tip total.
        return totalCandidates.max() ?? lines.flatMap(amounts(in:)).max()
    }

    /// Matches money like "42.50", "$1,234.56" or "18,90".
    private static let amountRegex = #/\d{1,3}(?:,\d{3})+\.\d{2}|\d+[.,]\d{2}/#

    /// Text recognition sometimes adds a space after a separator, reading "1,050.00" as "1, 050.00".
    private static let splitNumberRegex = #/(\d)([,.])\s+(\d)/#

    private static func amounts(in line: String) -> [Double] {
        let line = line.replacing(splitNumberRegex) { "\($0.1)\($0.2)\($0.3)" }
        return line.matches(of: amountRegex).compactMap { match in
            var text = String(match.output)
            if text.contains(".") {
                text.removeAll { $0 == "," }   // "1,234.56": comma separates thousands
            } else {
                text = text.replacingOccurrences(of: ",", with: ".")  // "18,90": comma is the decimal point
            }
            return Double(text)
        }
    }
}
