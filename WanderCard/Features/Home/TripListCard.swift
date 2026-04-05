import SwiftUI

struct TripListCard: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 24)
                .fill(coverGradient)
                .frame(height: 164)
                .overlay(alignment: .bottomTrailing) {
                    Text("📸 \(trip.cardCount)장의 카드")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.35), in: Capsule())
                        .foregroundStyle(.white)
                        .padding(14)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(trip.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("\(trip.startDate.formattedTripDateRange()) – \(trip.endDate.formattedTripDateRange()) · \(trip.durationDays)일")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 14, y: 6)
    }

    private var coverGradient: LinearGradient {
        let gradients: [[Color]] = [
            [.orange, .pink],
            [.purple, .mint],
            [.green, .cyan]
        ]
        let index = abs(trip.id.uuidString.hashValue) % gradients.count
        return LinearGradient(colors: gradients[index], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
