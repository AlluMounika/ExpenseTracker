//
//  ExpenseRow.swift
//  ExpenseTracker
//

import SwiftUI

struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.restaurantName)
                    .font(.headline)
                Text(expense.date, format: .dateTime.day().month(.abbreviated).year())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(expense.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                .font(.headline)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        ExpenseRow(expense: Expense(date: .now, restaurantName: "Olive Garden", amount: 42.50))
    }
}
