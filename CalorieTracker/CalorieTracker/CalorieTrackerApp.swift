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
    @AppStorage("userName")     var userName: String = ""
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
    @AppStorage("hasSeenNamePrompt")    var hasSeenNamePrompt: Bool = false
    @AppStorage("targetWeightKg")       var targetWeightKg: Double = 0
    @AppStorage("heightCm")             var heightCm: Int = 0
    @AppStorage("weightFromHealth")     var weightFromHealth: Bool = false
    @AppStorage("appLanguage")          private(set) var appLanguageRaw: String = AppLanguage.system.rawValue

    var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .system
    }

    func setLanguage(_ lang: AppLanguage) {
        appLanguageRaw = lang.rawValue
        if let code = lang.localeCode {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
    }

    // MARK: Live state

    @Published var loggedMeals: [LoggedMeal] = []
    @Published var caloriesBurnedToday: Int = 0
    @Published var activitiesToday: [Activity] = []
    @Published var healthKitAuthorized: Bool = false
    @Published var weights: [WeightEntry] = []

    let healthKit = HealthKitService()

    // MARK: Lifecycle

    init() {
        if memberSinceTimestamp == 0 {
            memberSinceTimestamp = Date().timeIntervalSince1970
        }
        loggedMeals = LoggedMeal.loadAll()
        weights = WeightEntry.loadAll()
    }

    // MARK: Effective daily goal

    /// Daily calorie goal adjusted for activity burn — i.e. the amount the
    /// user can actually eat today and still hit their target.
    var effectiveGoalToday: Int { goal + caloriesBurnedToday }

    // MARK: Weight tracking

    var latestWeightKg: Double? {
        weights.sorted { $0.date < $1.date }.last?.kg
    }

    func addWeight(_ kg: Double, on date: Date = Date()) {
        let entry = WeightEntry(date: date, kg: kg)
        weights.append(entry)
        weights.sort { $0.date < $1.date }
        WeightEntry.saveAll(weights)
    }

    func removeWeight(_ entry: WeightEntry) {
        weights.removeAll { $0.id == entry.id }
        WeightEntry.saveAll(weights)
    }

    func syncWeightsFromHealth() async {
        guard healthKitAuthorized else { return }
        let pulled = await healthKit.bodyMassHistory(days: 365)
        let manual = weights.filter { entry in
            !pulled.contains(where: { abs($0.date.timeIntervalSince(entry.date)) < 60 })
        }
        let merged = (manual + pulled).sorted { $0.date < $1.date }
        weights = merged
        WeightEntry.saveAll(merged)
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

        if weightFromHealth {
            await syncWeightsFromHealth()
        }
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

    // MARK: Diary / Trends

    private var mealsByDay: [Date: [LoggedMeal]] {
        Dictionary(grouping: loggedMeals) { Calendar.current.startOfDay(for: $0.timestamp) }
    }

    /// Most recent N days that contain at least one logged meal, plus
    /// today (always included even when empty).
    func recentDays(limit: Int = 14) -> [DayRecord] {
        let cal = Calendar.current
        let grouped = mealsByDay
        let today = cal.startOfDay(for: Date())

        let dayDate = DateFormatter()
        dayDate.dateFormat = "MMM d"
        let weekday = DateFormatter()
        weekday.dateFormat = "EEE"

        var records: [DayRecord] = []
        for offset in 0..<60 {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { break }
            let mealsOnDay = (grouped[day] ?? []).sorted { $0.timestamp < $1.timestamp }
            if mealsOnDay.isEmpty && offset != 0 { continue }

            let label: String
            switch offset {
            case 0: label = "Today"
            case 1: label = "Yesterday"
            default: label = weekday.string(from: day)
            }

            let consumed = mealsOnDay.map(\.kcal).reduce(0, +)
            records.append(DayRecord(
                label: label,
                date: dayDate.string(from: day),
                consumed: consumed,
                storedGoal: nil,
                mealCount: mealsOnDay.count,
                meals: mealsOnDay.map(\.asMeal)
            ))
            if records.count >= limit { break }
        }
        return records
    }

    func weekTrendEntries() -> [TrendEntry] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let grouped = mealsByDay
        let wf = DateFormatter(); wf.dateFormat = "EEE"
        return (0..<7).reversed().compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let meals = grouped[day] ?? []
            return TrendEntry(
                label: wf.string(from: day),
                consumed: meals.map(\.kcal).reduce(0, +),
                quality: meals.isEmpty ? 0 : meals.map(\.quality).reduce(0, +) / meals.count
            )
        }
    }

    func monthTrendEntries() -> [TrendEntry] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let grouped = mealsByDay
        return (0..<30).reversed().compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let meals = grouped[day] ?? []
            return TrendEntry(
                label: "\(cal.component(.day, from: day))",
                consumed: meals.map(\.kcal).reduce(0, +),
                quality: meals.isEmpty ? 0 : meals.map(\.quality).reduce(0, +) / meals.count
            )
        }
    }

    func yearTrendEntries() -> [TrendEntry] {
        let cal = Calendar.current
        let mf = DateFormatter(); mf.dateFormat = "MMM"
        let today = Date()
        let grouped: [DateComponents: [LoggedMeal]] = Dictionary(grouping: loggedMeals) {
            cal.dateComponents([.year, .month], from: $0.timestamp)
        }
        return (0..<12).reversed().compactMap { offset in
            guard let date = cal.date(byAdding: .month, value: -offset, to: today) else { return nil }
            let key = cal.dateComponents([.year, .month], from: date)
            let meals = grouped[key] ?? []
            let daysInMonth = cal.range(of: .day, in: .month, for: date)?.count ?? 30
            let totalKcal = meals.map(\.kcal).reduce(0, +)
            return TrendEntry(
                label: mf.string(from: date),
                consumed: totalKcal / max(1, daysInMonth),
                quality: meals.isEmpty ? 0 : meals.map(\.quality).reduce(0, +) / meals.count
            )
        }
    }

    /// (protein%, carbs%, fat%) of total kcal across logged meals; sums to 100 when any data exists.
    func macroPercents() -> (Int, Int, Int) {
        let p = loggedMeals.map { $0.protein * 4 }.reduce(0, +)
        let c = loggedMeals.map { $0.carbs   * 4 }.reduce(0, +)
        let f = loggedMeals.map { $0.fat     * 9 }.reduce(0, +)
        let total = p + c + f
        guard total > 0 else { return (0, 0, 0) }
        let pp = Int((Double(p) / Double(total) * 100).rounded())
        let cc = Int((Double(c) / Double(total) * 100).rounded())
        return (pp, cc, max(0, 100 - pp - cc))
    }
}
