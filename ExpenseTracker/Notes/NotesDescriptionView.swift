//
//  NotesDescriptionView.swift
//  ExpenseTracker
//
//  Created by Mohana Krishna Narsupalli on 30/10/26.
//

import SwiftUI

struct NotesDescriptionView: View {
    
    let initialText: String
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""
    @FocusState private var isFocused: Bool
    
    private var hasChanges: Bool { draft != initialText }

    var body: some View {
        NavigationStack {
            TextEditor(text: $draft)
                .focused($isFocused)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(.horizontal)
                .overlay(alignment: .topLeading) {
                    if draft.isEmpty {
                        Text("How did you feel about this expense?")
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 21)
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                }
                .navigationTitle("Note")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            onSave(draft)
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .bottomBar) {
                        Text("\(draft.count) characters")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onAppear {
                    draft = initialText
                    isFocused = true
                }
        }.interactiveDismissDisabled(hasChanges)
    }
}
