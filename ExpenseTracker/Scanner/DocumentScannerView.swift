//
//  DocumentScannerView.swift
//  ExpenseTracker
//
//  Created by Mohana Krishna Narsupalli on 29/10/26.
//

import SwiftUI
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
    /// Called once when the scanner closes. The image is nil if the user cancelled or it failed.
    let onFinish: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController,
                                context: Context) {
        // Nothing to update: the scanner manages itself.
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onFinish: (UIImage?) -> Void

        init(onFinish: @escaping (UIImage?) -> Void) {
            self.onFinish = onFinish
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            let image = scan.pageCount > 0 ? scan.imageOfPage(at: 0) : nil
            onFinish(image)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onFinish(nil)
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFailWithError error: Error) {
            onFinish(nil)
        }
    }
}
