import CoreLocation
import Photos
import PhotosUI
import UIKit

@MainActor
final class PhotoLibraryService: ObservableObject {
    var authorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    func fetchPhotos(for trip: Trip) async throws -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        options.predicate = NSPredicate(
            format: "creationDate >= %@ AND creationDate <= %@",
            trip.startDate as NSDate,
            trip.endDate as NSDate
        )
        let result = PHAsset.fetchAssets(with: .image, options: options)
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in assets.append(asset) }
        return assets
    }

    func fetchImage(for asset: PHAsset, targetSize: CGSize) async throws -> CGImage? {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image?.cgImage)
            }
        }
    }

    func createTripCover(from assets: [PHAsset]) async -> CGImage? {
        guard let last = assets.last else { return nil }
        return try? await fetchImage(for: last, targetSize: CGSize(width: 1200, height: 1200))
    }

    func suggestTrips() async throws -> [TripSuggestion] {
        [
            TripSuggestion(name: "도쿄", startDate: .now.addingTimeInterval(-86400 * 6), endDate: .now, photoCount: 42, locationName: "도쿄, 일본"),
            TripSuggestion(name: "제주", startDate: .now.addingTimeInterval(-86400 * 32), endDate: .now.addingTimeInterval(-86400 * 29), photoCount: 18, locationName: "제주, 한국")
        ]
    }
}

struct TripSuggestion: Identifiable {
    let id = UUID()
    let name: String
    let startDate: Date
    let endDate: Date
    let photoCount: Int
    let locationName: String
}
