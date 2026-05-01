import SwiftUI

@main
struct CalorieTrackerApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(appState.isDark ? .dark : .light)
        }
    }
}

class AppState: ObservableObject {
    @AppStorage("calorieGoal") var goal: Int = 2200
    @AppStorage("userName") var userName: String = "Alex"
    @AppStorage("isDark") var isDark: Bool = false
    @AppStorage("claudeApiKey") var claudeApiKey: String = ""
}
