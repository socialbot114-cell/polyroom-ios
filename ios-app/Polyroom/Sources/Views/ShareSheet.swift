import Foundation

#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import UIKit

/// Native iOS share sheet for the locally rendered room snapshot.
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
#endif
