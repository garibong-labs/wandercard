import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \Trip.startDate, order: .reverse) private var trips: [Trip]
    @State private var viewModel = TripsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                if trips.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(trips) { trip in
                            NavigationLink(value: trip) {
                                TripListCard(trip: trip)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("내 여행")
            .navigationDestination(for: Trip.self) { trip in
                TripDetailView(trip: trip)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        appState.presentCreateCard()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                TabBarStub(activeTab: .trips) {
                    appState.presentSettings()
                }
            }
            .onAppear {
                viewModel.seedIfNeeded(context: modelContext)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 54))
                .foregroundStyle(.secondary)
            Text("아직 여행이 없어요")
                .font(.title3.bold())
            Text("사진 접근을 허용하고 첫 여행 카드를 만들어봐.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("첫 카드 만들기") {
                appState.presentCreateCard()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 120)
        .padding(.horizontal, 32)
    }
}

private struct TabBarStub: View {
    enum Tab {
        case trips
    }

    let activeTab: Tab
    let settingsAction: () -> Void

    var body: some View {
        HStack {
            tab(icon: "square.stack.fill", title: "여행", isActive: activeTab == .trips)
            tab(icon: "map.fill", title: "지도", isActive: false)
            Button(action: settingsAction) {
                VStack(spacing: 4) {
                    Image(systemName: "gearshape.fill")
                    Text("설정")
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(.ultraThinMaterial)
    }

    private func tab(icon: String, title: String, isActive: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
            Text(title)
                .font(.caption2)
        }
        .frame(maxWidth: .infinity)
        .foregroundStyle(isActive ? Color.accentColor : Color.secondary)
    }
}
