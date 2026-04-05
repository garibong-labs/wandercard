import Foundation
import SwiftData

@Model
final class TravelCard {
    var id: UUID
    var tripId: UUID
    var photoLocalIdentifier: String
    var textContent: String?
    var sourceURLString: String?
    var locationName: String?
    var locationLatitude: Double?
    var locationLongitude: Double?
    var templateTypeRawValue: String
    var renderedImageLocalPath: String?
    var createdAt: Date
    var sortOrder: Int
    var trip: Trip?

    init(
        id: UUID = UUID(),
        tripId: UUID,
        photoLocalIdentifier: String,
        textContent: String? = nil,
        sourceURL: URL? = nil,
        locationName: String? = nil,
        locationLatitude: Double? = nil,
        locationLongitude: Double? = nil,
        templateType: CardTemplateType,
        renderedImageLocalPath: String? = nil,
        createdAt: Date = .now,
        sortOrder: Int = 0,
        trip: Trip? = nil
    ) {
        self.id = id
        self.tripId = tripId
        self.photoLocalIdentifier = photoLocalIdentifier
        self.textContent = textContent
        self.sourceURLString = sourceURL?.absoluteString
        self.locationName = locationName
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        self.templateTypeRawValue = templateType.rawValue
        self.renderedImageLocalPath = renderedImageLocalPath
        self.createdAt = createdAt
        self.sortOrder = sortOrder
        self.trip = trip
    }

    var sourceURL: URL? {
        get { sourceURLString.flatMap(URL.init(string:)) }
        set { sourceURLString = newValue?.absoluteString }
    }

    var templateType: CardTemplateType {
        get { CardTemplateType(rawValue: templateTypeRawValue) ?? .light }
        set { templateTypeRawValue = newValue.rawValue }
    }
}
