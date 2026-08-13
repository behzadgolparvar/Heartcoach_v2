import SwiftUI
import Firebase
import FirebaseFirestore

@main
struct HeartCoachApp: App {
    @State private var container: AppContainer

    init() {
        FirebaseApp.configure()
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        Firestore.firestore().settings = settings
        _container = State(initialValue: AppContainer())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container)
                .environment(container.authViewModel)
                .environment(container.onboardingViewModel)
                .environment(container.homeViewModel)
                .environment(container.settingsViewModel)
                .environment(container.summaryViewModel)
                .environment(container.historyViewModel)
        }
    }
}
