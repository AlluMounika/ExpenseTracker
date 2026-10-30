//
//  ContentView.swift
//  ExpenseTracker
//
//  Created by Mohana Krishna Narsupalli on 27/10/26.
//

import SwiftUI

struct ContentView: View {
    @State private var store = ExpenseStore()
    @State private var scannerViewModel = ReceiptScannerViewModel()
    @State private var isShowingReceiptScanner = false
    @State private var expenseForNote: Expense?

    private var expenses: [Expense] {
        store.expenses
    }

    private var isShowingScanError: Binding<Bool> {
        Binding(
            get: { scannerViewModel.errorMessage != nil },
            set: { if !$0 { scannerViewModel.errorMessage = nil } }
        )
    }

    private var totalAmount: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                totalHeader
                ExpenseTableView(expenses: expenses) { expense in
                    expenseForNote = expense
                }
            }
            .navigationTitle("Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingReceiptScanner = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Scan receipt")
                }
            }
            .sheet(isPresented: $isShowingReceiptScanner) {
                ReceiptScannerView(viewModel: scannerViewModel)
            }
            .sheet(item: $expenseForNote) { expense in
                NotesDescriptionView(initialText: NoteStorage.load(for: expense.id)) { text in
                    NoteStorage.save(text, for: expense.id)
                }
            }
            .onChange(of: scannerViewModel.scannedExpense) { _, expense in
                if let expense {
                    store.add(expense)
                }
            }
            .alert("Couldn't Read Receipt", isPresented: isShowingScanError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(scannerViewModel.errorMessage ?? "")
            }
        }
    }

    private var totalHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Expense")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if scannerViewModel.isProcessing {
                    Label("Reading receipt…", systemImage: "doc.text.viewfinder")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(expenses.count) transactions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(totalAmount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                .font(.title.bold())
                .monospacedDigit()
        }
        .padding()
        .background(.thinMaterial)
    }
}

#Preview {
    ContentView()
}
