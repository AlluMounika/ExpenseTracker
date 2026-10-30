//
//  ReceiptScannerViewModel.swift
//  ExpenseTracker
//

import Observation
import UIKit

@Observable
final class ReceiptScannerViewModel {
    /// The receipt the user confirmed with Done, ready for the next processing step.
    private(set) var receiptImage: UIImage?
    private(set) var details: ReceiptDetails?
    /// The expense built from the last scanned receipt, for the expense list to pick up.
    private(set) var scannedExpense: Expense?
    private(set) var isProcessing = false
    var errorMessage: String?

    private let recognizer = ReceiptTextRecognizer()

    func submit(_ image: UIImage) {
        receiptImage = image
        Task { await extractDetails(from: image) }
    }

    /// Reads the receipt's text with Vision and pulls out the restaurant name, date and amount.
    func extractDetails(from image: UIImage) async {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        do {
            let lines = try await recognizer.recognizeLines(in: image)
            let details = ReceiptTextParser.parse(lines: lines)
            self.details = details
            print("Receipt text:\n\(lines.joined(separator: "\n"))")
            print("Extracted receipt details: \(details)")

            // The amount is the one detail an expense can't do without.
            guard let amount = details.amount else {
                errorMessage = "Couldn't find a total on this receipt. Try scanning it again with the total clearly visible."
                return
            }
            scannedExpense = Expense(
                date: details.date ?? .now,
                restaurantName: details.restaurantName ?? "Unknown Restaurant",
                amount: amount
            )
        } catch {
            errorMessage = error.localizedDescription
            print("Receipt text recognition failed: \(error)")
        }
    }
}
