import Foundation
import UIKit

struct SharedPayload: Equatable {
    var text: String?
    var url: URL?
    var imagePath: String?
}

@Observable
final class SharedPendingStore {
    static let suiteName = "group.dev.garibong.wandercard"
    private let defaults = UserDefaults(suiteName: suiteName)
    private let textKey = "shared_pending_text"
    private let urlKey = "shared_pending_url"
    private let imagePathKey = "shared_pending_image_path"

    var payload = SharedPayload()

    func save(text: String?, url: URL?, imagePath: String?) {
        defaults?.set(text, forKey: textKey)
        defaults?.set(url?.absoluteString, forKey: urlKey)
        defaults?.set(imagePath, forKey: imagePathKey)
    }

    func loadPendingPayload() {
        payload = SharedPayload(
            text: defaults?.string(forKey: textKey),
            url: defaults?.string(forKey: urlKey).flatMap(URL.init(string:)),
            imagePath: defaults?.string(forKey: imagePathKey)
        )
    }

    func consume() -> SharedPayload {
        loadPendingPayload()
        let current = payload
        clear()
        return current
    }

    func clear() {
        defaults?.removeObject(forKey: textKey)
        defaults?.removeObject(forKey: urlKey)
        defaults?.removeObject(forKey: imagePathKey)
        payload = SharedPayload()
    }

    func loadImage() -> UIImage? {
        guard let imagePath = payload.imagePath else { return nil }
        return UIImage(contentsOfFile: imagePath)
    }
}
