//
//  NoteStorage.swift
//  ExpenseTracker
//

import Foundation

/// Saves each expense's note as a text file named after the expense's id,
/// in `Documents/Notes/<id>.txt`.
enum NoteStorage {
    private static var notesDirectory: URL {
        URL.documentsDirectory.appending(path: "Notes", directoryHint: .isDirectory)
    }

    private static func fileURL(for id: UUID) -> URL {
        notesDirectory.appending(path: "\(id.uuidString).txt")
    }

    static func load(for id: UUID) -> String {
        (try? String(contentsOf: fileURL(for: id), encoding: .utf8)) ?? ""
    }

    static func save(_ text: String, for id: UUID) {
        let url = fileURL(for: id)
        do {
            // An emptied note removes the file rather than leaving a blank one behind.
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if FileManager.default.fileExists(atPath: url.path()) {
                    try FileManager.default.removeItem(at: url)
                }
                return
            }
            try FileManager.default.createDirectory(at: notesDirectory, withIntermediateDirectories: true)
            try text.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print("NoteStorage: failed to save note \(url.lastPathComponent): \(error)")
        }
    }
}
