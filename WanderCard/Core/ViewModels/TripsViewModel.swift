import Foundation
import SwiftData

@Observable
final class TripsViewModel {
    func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Trip>()
        if (try? context.fetchCount(descriptor)) ?? 0 > 0 {
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let trips = [
            Trip(name: "도쿄 봄 여행", startDate: calendar.date(byAdding: .day, value: -120, to: now)!, endDate: calendar.date(byAdding: .day, value: -115, to: now)!, photoCount: 47, cardCount: 3),
            Trip(name: "제주도 드라이브", startDate: calendar.date(byAdding: .day, value: -60, to: now)!, endDate: calendar.date(byAdding: .day, value: -58, to: now)!, photoCount: 32, cardCount: 2),
            Trip(name: "교토 단풍", startDate: calendar.date(byAdding: .day, value: 30, to: now)!, endDate: calendar.date(byAdding: .day, value: 33, to: now)!, photoCount: 28, cardCount: 0)
        ]

        for trip in trips {
            context.insert(trip)
        }
        try? context.save()
    }
}
