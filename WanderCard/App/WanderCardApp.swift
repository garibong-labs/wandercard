import SwiftData
import SwiftUI

@main
struct WanderCardApp: App {
    @AppStorage("isOnboardingShown") private var isOnboardingShown = false
    @State private var appState = AppState()
    private let sharedStore = SharedPendingStore()
    private let processInfo = ProcessInfo.processInfo

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(sharedStore)
                .modelContainer(SharedModelContainer.container)
                .task {
                    if processInfo.arguments.contains("-skipOnboarding") {
                        isOnboardingShown = true
                    }
                    if processInfo.arguments.contains("-openCreateCard") {
                        appState.presentCreateCard()
                    }
                }
                .onOpenURL { url in
                    appState.handleIncoming(url: url, store: sharedStore)
                }
                .sheet(isPresented: onboardingBinding) {
                    OnboardingView(isPresented: onboardingBinding)
                        .interactiveDismissDisabled()
                }
        }
    }

    private var onboardingBinding: Binding<Bool> {
        Binding(
            get: { !isOnboardingShown && appState.canPresentOnboarding },
            set: { newValue in
                if !newValue {
                    isOnboardingShown = true
                }
            }
        )
    }
}

private struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        let activeSheet = Binding(
            get: { appState.activeSheet },
            set: { appState.activeSheet = $0 }
        )

        HomeView()
            .sheet(item: activeSheet) { sheet in
                switch sheet {
                case .createCard(let trip):
                    NavigationStack {
                        CreateCardView(trip: trip)
                    }
                case .settings:
                    NavigationStack {
                        SettingsView()
                    }
                }
            }
    }
}

@Observable
final class AppState {
    enum ActiveSheet: Identifiable {
        case createCard(Trip?)
        case settings

        var id: String {
            switch self {
            case .createCard(let trip):
                "create-\(trip?.persistentModelID.hashValue ?? 0)"
            case .settings:
                "settings"
            }
        }
    }

    var activeSheet: ActiveSheet?
    var canPresentOnboarding = true

    func presentCreateCard(for trip: Trip? = nil) {
        activeSheet = .createCard(trip)
    }

    func presentSettings() {
        activeSheet = .settings
    }

    func handleIncoming(url: URL, store: SharedPendingStore) {
        guard url.scheme == "wandercard" else { return }
        store.loadPendingPayload()
        activeSheet = .createCard(nil)
    }
}
