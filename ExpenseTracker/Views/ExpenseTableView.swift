//
//  ExpenseTableView.swift
//  ExpenseTracker
//

import SwiftUI

struct ExpenseTableView: View {
    let expenses: [Expense]
    var onSelect: (Expense) -> Void = { _ in }

    var body: some View {
        List(expenses) { expense in
            Button {
                onSelect(expense)
            } label: {
                ExpenseRow(expense: expense)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
        .overlay {
            if expenses.isEmpty {
                ContentUnavailableView("No Expenses", systemImage: "fork.knife")
            }
        }
    }
}

#Preview {
    ExpenseTableView(expenses: ExpenseStore().expenses)
}
