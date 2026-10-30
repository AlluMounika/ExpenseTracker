//
//  Expense.swift
//  ExpenseTracker
//

import Foundation
import Observation

struct Expense: Identifiable, Codable, Hashable {
    /// Saved in the JSON so it stays the same across launches; notes are stored under it.
    let id: UUID
    let date: Date
    let restaurantName: String
    let amount: Double

    init(id: UUID = UUID(), date: Date, restaurantName: String, amount: Double) {
        self.id = id
        self.date = date
        self.restaurantName = restaurantName
        self.amount = amount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Entries saved before ids were stored get a new one, which is then saved.
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try container.decode(Date.self, forKey: .date)
        restaurantName = try container.decode(String.self, forKey: .restaurantName)
        amount = try container.decode(Double.self, forKey: .amount)
    }
}

/// Owns the list of expenses and keeps it saved as `expenses.json`.
///
/// The JSON bundled with the app is read-only, so the first launch starts from it and
/// every change is written to a copy in the app's Documents folder, which is used from then on.
@Observable
final class ExpenseStore {
    private(set) var expenses: [Expense] = []

    private let fileName: String
    private let bundle: Bundle

    init(fileName: String = "expenses", bundle: Bundle = .main) {
        self.fileName = fileName
        self.bundle = bundle
        if let loaded = load() {
            expenses = loaded
            // Save right away so any ids created while loading are kept for next launch.
            save()
        }
    }

    func add(_ expense: Expense) {
        expenses.append(expense)
        expenses.sort { $0.date > $1.date }
        save()
    }

    // MARK: - Persistence

    private var savedFileURL: URL {
        URL.documentsDirectory.appending(path: "\(fileName).json")
    }

    /// Dates are stored as `yyyy-MM-dd`, matching the bundled file.
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Returns nil when there's nothing to load or the file can't be read,
    /// so a damaged saved file is never overwritten with an empty list.
    private func load() -> [Expense]? {
        let url: URL
        if FileManager.default.fileExists(atPath: savedFileURL.path()) {
            url = savedFileURL
        } else if let bundledURL = bundle.url(forResource: fileName, withExtension: "json") {
            url = bundledURL
        } else {
            print("ExpenseStore: \(fileName).json not found")
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Self.dateFormatter)

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode([Expense].self, from: data)
                .sorted { $0.date > $1.date }
        } catch {
            print("ExpenseStore: failed to decode \(url.lastPathComponent): \(error)")
            return nil
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(Self.dateFormatter)
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(expenses)
            try data.write(to: savedFileURL, options: .atomic)
        } catch {
            print("ExpenseStore: failed to save \(savedFileURL.lastPathComponent): \(error)")
        }
    }
}
