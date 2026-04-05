import Foundation
import SwiftData
import os.log

@MainActor
enum SharedModelContainer {
    static let appGroupIdentifier = "group.dev.garibong.wandercard"

    static var container: ModelContainer = {
        let schema = Schema([Trip.self, TravelCard.self])
        let configuration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            os_log(.error, "Failed to build shared model container: %{public}@", error.localizedDescription)
            do {
                return try ModelContainer(for: schema)
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    private static var storeURL: URL {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            return url.appendingPathComponent("WanderCard.store")
        }
        return URL.applicationSupportDirectory.appendingPathComponent("WanderCard.store")
    }
}
