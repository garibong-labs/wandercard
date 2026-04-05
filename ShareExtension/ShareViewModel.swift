import Foundation
import SwiftUI
import UniformTypeIdentifiers
import UIKit

@MainActor
@Observable
final class ShareViewModel {
    var sharedText: String?
    var sharedURL: URL?
    var sharedImage: UIImage?

    private weak var extensionContext: NSExtensionContext?
    private let store = SharedPendingStore()

    init(extensionContext: NSExtensionContext?) {
        self.extensionContext = extensionContext
    }

    func loadItems() async {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { return }
        for item in items {
            for provider in item.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
                   let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
                    sharedText = text
                }
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
                   let url = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
                    sharedURL = url
                }
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier),
                   let image = try? await loadImage(from: provider) {
                    sharedImage = image
                }
            }
        }
    }

    func openMainApp() async {
        let imagePath = sharedImage.flatMap(saveImageToAppGroup(_:))
        store.save(text: sharedText, url: sharedURL, imagePath: imagePath)
        guard let url = URL(string: "wandercard://share") else { return }
        _ = extensionContext?.open(url, completionHandler: { [weak self] _ in
            self?.extensionContext?.completeRequest(returningItems: nil)
        })
    }

    private func loadImage(from provider: NSItemProvider) async throws -> UIImage {
        if let url = try await provider.loadItem(forTypeIdentifier: UTType.image.identifier) as? URL,
           let image = UIImage(contentsOfFile: url.path) {
            return image
        }
        if let data = try await provider.loadItem(forTypeIdentifier: UTType.image.identifier) as? Data,
           let image = UIImage(data: data) {
            return image
        }
        throw NSError(domain: "WanderCardShare", code: 0)
    }

    private func saveImageToAppGroup(_ image: UIImage) -> String? {
        guard let data = image.pngData(),
              let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedPendingStore.suiteName) else {
            return nil
        }
        let url = container.appendingPathComponent("shared-\(UUID().uuidString).png")
        try? data.write(to: url)
        return url.path
    }
}
