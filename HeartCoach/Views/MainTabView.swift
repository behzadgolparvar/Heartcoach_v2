import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            HistoryView()
                .tabItem { Label("History", systemImage: "list.bullet") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .preferredColorScheme(.dark)
    }
}
