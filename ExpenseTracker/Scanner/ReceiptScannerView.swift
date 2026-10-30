//
//  ReceiptScannerView.swift
//  ExpenseTracker
//
//  Created by Mohana Krishna Narsupalli on 29/10/26.
//

import PhotosUI
import SwiftUI
import VisionKit

struct ReceiptScannerView: View {
    @State private var receiptImage: UIImage?
    @State private var pickerItem: PhotosPickerItem?
    @State private var isShowingScanner = false
    /// Owned by the presenting view so processing keeps going after this sheet closes.
    let viewModel: ReceiptScannerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                receiptFrame
                actionButtons
                Spacer()
            }
            .padding()
            .navigationTitle("Scan Receipt")
            .fullScreenCover(isPresented: $isShowingScanner) {
                DocumentScannerView { image in
                    if let image { receiptImage = image }
                    isShowingScanner = false
                }
                .ignoresSafeArea()
            }
            .onChange(of: pickerItem) { _, newItem in
                Task { await loadImage(from: newItem) }
            }
        }
    }

    // MARK: - Bordered frame

    private var receiptFrame: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))

            if let receiptImage {
                Image(uiImage: receiptImage)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 48))
                    Text("No receipt yet")
                        .font(.headline)
                    Text("Scan one with the camera or choose from Photos")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.secondary)
                .padding()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 420)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    receiptImage == nil ? Color.secondary : Color.accentColor,
                    style: StrokeStyle(lineWidth: 2,
                                       dash: receiptImage == nil ? [8, 6] : [])
                )
        )
    }

    // MARK: - Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            if let receiptImage {
                Button(role: .cancel) {
                    clearReceipt()
                } label: {
                    Label("Cancel", systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    viewModel.submit(receiptImage)
                    dismiss()
                } label: {
                    Label("Done", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    isShowingScanner = true
                } label: {
                    Label("Scan", systemImage: "camera.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!VNDocumentCameraViewController.isSupported)

                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label("Photos", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .controlSize(.large)
    }

    // MARK: - Temporary (moves to the ViewModel in Step 2)

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        receiptImage = image
    }

    /// Clears the receipt so the Scan and Photos buttons come back.
    private func clearReceipt() {
        receiptImage = nil
        // Reset the selection too, so picking the same photo again still triggers onChange.
        pickerItem = nil
    }
}

#Preview {
    ReceiptScannerView(viewModel: ReceiptScannerViewModel())
}
