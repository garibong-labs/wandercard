import SwiftUI

struct TripDetailView: View {
    @Environment(AppState.self) private var appState
    let trip: Trip

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if trip.cards.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(trip.cards.sorted(by: { $0.sortOrder < $1.sortOrder })) { card in
                            NavigationLink {
                                CardPreviewView(card: card)
                            } label: {
                                CardThumbnailView(card: card)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 80)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("카드 만들기") {
                    appState.presentCreateCard(for: trip)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(trip.name)
                .font(.title.bold())
                .foregroundStyle(.white)
            Text("\(trip.startDate.formattedTripDateRange()) – \(trip.endDate.formattedTripDateRange()) · \(trip.durationDays)일")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
            HStack(spacing: 10) {
                stat("📸 \(trip.cardCount) 카드")
                stat("🖼 \(trip.photoCount) 사진")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func stat(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(0.18), in: Capsule())
            .foregroundStyle(.white)
    }

    private var emptyState: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("아직 카드가 없어요")
                .font(.headline)
            Text("사진 한 장과 짧은 메모로 첫 카드를 만들어봐.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("첫 카드 만들기") {
                appState.presentCreateCard(for: trip)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct CardThumbnailView: View {
    let card: TravelCard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ImageLoaderView(path: card.renderedImageLocalPath)
                .frame(height: 210)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            Text(card.textContent ?? "메모 없음")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
            Text(card.locationName ?? "위치 없음")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }
}
