import Foundation
import SwiftData

@Model
final class Trip {
    var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var photoCount: Int
    var cardCount: Int
    var coverImageLocalPath: String?
    @Relationship(deleteRule: .cascade, inverse: \TravelCard.trip) var cards: [TravelCard]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        startDate: Date,
        endDate: Date,
        photoCount: Int = 0,
        cardCount: Int = 0,
        coverImageLocalPath: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.photoCount = photoCount
        self.cardCount = cardCount
        self.coverImageLocalPath = coverImageLocalPath
        self.cards = []
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var durationDays: Int {
        let days = Calendar.current.dateComponents([.day], from: startDate.startOfDay, to: endDate.startOfDay).day ?? 0
        return max(1, days + 1)
    }
}
