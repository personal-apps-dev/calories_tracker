import SwiftUI

@main
struct CalorieTrackerApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(appState.isDark ? .dark : .light)
                .task { await appState.bootstrap() }
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    // MARK: Persistent settings

    @AppStorage("calorieGoal")  var goal: Int = 2200
    @AppStorage("userName")     var userName: String = "Friend"
    @AppStorage("isDark")       var isDark: Bool = false
    @AppStorage("claudeApiKey") var claudeApiKey: String = ""

    @AppStorage("memberSinceTimestamp") private var memberSinceTimestamp: Double = 0
    @AppStorage("totalMealsLogged")     var totalMealsLogged: Int = 0
    @AppStorage("longestStreak")        var longestStreak: Int = 0
    @AppStorage("daysOnGoal")           var daysOnGoal: Int = 0
    @AppStorage("perfectQualityDays")   var perfectQualityDays: Int = 0
    @AppStorage("activeDays")           var activeDays: Int = 0
    @AppStorage("healthKitEnabled")     var healthKitEnabled: Bool = false
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = false

    // MARK: Live state

    @Published var loggedMeals: [LoggedMeal] = []
    @Published var caloriesBurnedToday: Int = 0
    @Published var activitiesToday: [Activity] = []
    @Published var healthKitAuthorized: Bool = false

    let healthKit = HealthKitService()

    // MARK: Lifecycle

    init() {
        if memberSinceTimestamp == 0 {
            memberSinceTimestamp = Date().timeIntervalSince1970
        }
        loggedMeals = LoggedMeal.loadAll()
    }

    func bootstrap() async {
        guard healthKit.isAvailable else { return }
        if healthKitEnabled {
            let ok = await healthKit.requestAuthorization()
            healthKitAuthorized = ok
            if ok { await refreshHealth() }
        }
    }

    // MARK: HealthKit

    func enableHealthKit() async {
        let ok = await healthKit.requestAuthorization()
        healthKitAuthorized = ok
        healthKitEnabled = ok
        if ok { await refreshHealth() }
    }

    func refreshHealth() async {
        async let burned = healthKit.todayActiveEnergyKcal()
        async let workouts = healthKit.todayWorkouts()
        let (b, w) = await (burned, workouts)
        caloriesBurnedToday = b
        activitiesToday = w
        if b >= 500 { activeDays = max(activeDays, 1) }
    }

    // MARK: Meal logging

    func logMeal(_ meal: LoggedMeal) {
        loggedMeals.append(meal)
        LoggedMeal.saveAll(loggedMeals)
        totalMealsLogged += 1
        recomputeStreak()
        updateDailyAchievementsCounters()
    }

    private func recomputeStreak() {
        let s = streak
        if s > longestStreak { longestStreak = s }
    }

    private func updateDailyAchievementsCounters() {
        if todayConsumedKcal > 0, todayConsumedKcal <= goal {
            daysOnGoal = max(daysOnGoal, 1)
        }
        if todayMeals.count >= 2, avgQualityToday >= 80 {
            perfectQualityDays = max(perfectQualityDays, 1)
        }
    }

    // MARK: Derived today values

    var memberSinceDate: Date { Date(timeIntervalSince1970: memberSinceTimestamp) }

    var memberSinceLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return "Member since \(f.string(from: memberSinceDate))"
    }

    var todayMeals: [Meal] {
        let cal = Calendar.current
        return loggedMeals
            .filter { cal.isDateInToday($0.timestamp) }
            .sorted { $0.timestamp < $1.timestamp }
            .map { $0.asMeal }
    }

    var todayConsumedKcal: Int { todayMeals.map(\.kcal).reduce(0, +) }

    var todayProteinG: Int {
        loggedMealsToday.map(\.protein).reduce(0, +)
    }
    var todayCarbsG: Int {
        loggedMealsToday.map(\.carbs).reduce(0, +)
    }
    var todayFatG: Int {
        loggedMealsToday.map(\.fat).reduce(0, +)
    }

    private var loggedMealsToday: [LoggedMeal] {
        let cal = Calendar.current
        return loggedMeals.filter { cal.isDateInToday($0.timestamp) }
    }

    var todayProteinStat: MacroStat { MacroStat(grams: todayProteinG, goal: 140) }
    var todayCarbsStat:   MacroStat { MacroStat(grams: todayCarbsG,   goal: 240) }
    var todayFatStat:     MacroStat { MacroStat(grams: todayFatG,     goal: 75) }

    var avgQualityToday: Int {
        let qs = todayMeals.map(\.quality)
        return qs.isEmpty ? 0 : qs.reduce(0, +) / qs.count
    }

    // Live-computed streak — dayKeys-based; surfaced as `streak`.
    var streak: Int {
        let cal = Calendar.current
        let dayKeys = Set(loggedMeals.map { cal.startOfDay(for: $0.timestamp) })
        var count = 0
        var day = cal.startOfDay(for: Date())
        while dayKeys.contains(day) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }
}
