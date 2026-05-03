import SwiftUI

func initials(for name: String) -> String {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? "?" : String(trimmed.prefix(1)).uppercased()
}

// MARK: - HomeView

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showGoalSheet: Bool
    var onAvatarTap: () -> Void = {}

    @State private var showAchievements = false
    @State private var selectedLogged: LoggedMeal?
    @State private var showBurnedSheet = false

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                streakPill
                ringSection
                macroAndQualityRow
                mealsSection
            }
            .padding(.bottom, 110)
        }
        .background(Color(UIColor.systemBackground))
        .scrollEdgeFade()
        .sheet(isPresented: $showAchievements) {
            AchievementsView()
        }
        .sheet(item: $selectedLogged) { lm in
            MealDetailView(meal: lm)
        }
        .sheet(isPresented: $showBurnedSheet) {
            BurnedSheetView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .refreshable {
            if appState.healthKitAuthorized { await appState.refreshHealth() }
        }
    }

    // MARK: Header

    var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateString)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                Group {
                    if appState.userName.isEmpty {
                        Text("Hey, there 👋")
                    } else {
                        Text("Hey, \(appState.userName) 👋")
                    }
                }
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.8)
            }
            Spacer()
            Button(action: onAvatarTap) {
                Circle()
                    .fill(LinearGradient(
                        colors: [accentOrange, Color(hex: "5B8DEF")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(initials(for: appState.userName))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open profile")
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: Streak pill

    var streakPill: some View {
        Button(action: { showAchievements = true }) {
            HStack(spacing: 6) {
                Text(streakEmoji(appState.streak)).font(.system(size: 14))
                Text("\(appState.streak) day streak")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 5)
            .padding(.leading, 10)
            .padding(.trailing, 10)
            .background(
                Capsule()
                    .fill(Color(UIColor.secondarySystemBackground))
                    .overlay(Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.bottom, 18)
    }

    // MARK: Ring + goal button

    var ringSection: some View {
        VStack(spacing: 10) {
            CalorieRingView(
                consumed: appState.todayConsumedKcal,
                goal: appState.effectiveGoalToday
            )
            HStack(spacing: 8) {
                Button(action: { showGoalSheet = true }) {
                    Label(
                        "Goal · \(appState.goal.formatted(.number)) kcal",
                        systemImage: "pencil"
                    )
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 14)
                    .background(
                        Capsule()
                            .fill(Color(UIColor.secondarySystemBackground))
                            .overlay(Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 1))
                    )
                }
                if appState.caloriesBurnedToday > 0 {
                    Button {
                        showBurnedSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10, weight: .semibold))
                            Text("+\(appState.caloriesBurnedToday) burned")
                                .font(.system(size: 12, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .semibold))
                                .opacity(0.7)
                        }
                        .foregroundColor(accentOrange)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 12)
                        .background(Capsule().fill(accentOrange.opacity(0.13)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.bottom, 24)
    }

    // MARK: Macros + Nutrition Score (side-by-side)

    var macroAndQualityRow: some View {
        HStack(alignment: .top, spacing: 10) {
            macroCardCompact
            qualityCardCompact
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    var macroCardCompact: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MACROS")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
                .tracking(0.6)
            VStack(spacing: 9) {
                CompactMacroRow(label: "Protein", stat: appState.todayProteinStat, color: Color(hex: "5B8DEF"))
                CompactMacroRow(label: "Carbs",   stat: appState.todayCarbsStat,   color: Color(hex: "F4B740"))
                CompactMacroRow(label: "Fat",     stat: appState.todayFatStat,     color: Color(hex: "E86A6A"))
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 156)
        .cardStyle()
    }

    var qualityCardCompact: some View {
        let avg = appState.avgQualityToday
        let qc = qualityColor(avg)
        return VStack(alignment: .leading, spacing: 8) {
            Text("NUTRITION SCORE")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
                .tracking(0.6)

            QualityRingView(value: avg, size: 76, strokeW: 8)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 2)

            HStack(spacing: 5) {
                Circle().fill(qc).frame(width: 5, height: 5)
                Text(appState.todayMeals.isEmpty ? "Log a meal" : qualityLabel(avg))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(qc)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.vertical, 3)
            .padding(.horizontal, 9)
            .background(Capsule().fill(qc.opacity(0.13)))
            .frame(maxWidth: .infinity, alignment: .center)

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 156)
        .cardStyle()
    }

    // MARK: Meals list

    var mealsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today's meals")
                    .font(.system(size: 18, weight: .bold))
                    .tracking(-0.4)
                Spacer()
                if !appState.todayMeals.isEmpty {
                    Text("\(appState.todayMeals.count) logged")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(accentOrange)
                }
            }
            .padding(.horizontal, 24)

            if appState.todayMeals.isEmpty {
                emptyMealsCard
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(appState.todayMeals.enumerated()), id: \.offset) { i, meal in
                        Button {
                            if let lm = appState.loggedMeals.first(where: { $0.id.hashValue == meal.id }) {
                                selectedLogged = lm
                            }
                        } label: {
                            MealRowView(meal: meal)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if i < appState.todayMeals.count - 1 {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 16)
                .cardStyle()
                .padding(.horizontal, 24)
            }
        }
    }

    var emptyMealsCard: some View {
        VStack(spacing: 8) {
            Text("📷")
                .font(.system(size: 32))
            Text("No meals logged today")
                .font(.system(size: 14, weight: .semibold))
            Text("Tap the camera button below to snap a meal and have it analyzed.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .cardStyle()
        .padding(.horizontal, 24)
    }
}

// MARK: - CalorieRingView

struct CalorieRingView: View {
    let consumed: Int
    let goal: Int

    private let size: CGFloat = 220
    private let strokeW: CGFloat = 14

    private var pct: Double { Double(consumed) / Double(max(1, goal)) }

    /// Color interpolates smoothly across stops:
    ///   pct 0.0 → orange   (just starting the day)
    ///   pct 1.0 → green    (hit the goal exactly)
    ///   pct 1.5 → red      (50% over)
    /// Below 0 clamps to orange, above 1.5 clamps to red.
    private static let stops: [(Double, (Double, Double, Double))] = [
        (0.0, (1.00, 0.42, 0.21)),  // FF6B35 — accent orange
        (1.0, (0.24, 0.71, 0.43)),  // 3DB46D — peak green
        (1.5, (0.91, 0.42, 0.42)),  // E86A6A — over red
    ]

    private static func gradientColor(for pct: Double) -> Color {
        let p = max(stops.first!.0, min(stops.last!.0, pct))
        for i in 0..<(stops.count - 1) {
            let a = stops[i], b = stops[i + 1]
            if p >= a.0 && p <= b.0 {
                let t = (p - a.0) / (b.0 - a.0)
                return Color(
                    red:   a.1.0 + (b.1.0 - a.1.0) * t,
                    green: a.1.1 + (b.1.1 - a.1.1) * t,
                    blue:  a.1.2 + (b.1.2 - a.1.2) * t
                )
            }
        }
        let last = stops.last!.1
        return Color(red: last.0, green: last.1, blue: last.2)
    }

    private var ringColor: Color { Self.gradientColor(for: pct) }

    private var progress: Double { min(1, pct) }
    private var isOver: Bool { pct > 1.0 }
    private var overProgress: Double {
        isOver ? min(1, Double(consumed - goal) / Double(max(1, goal))) : 0
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.06), lineWidth: strokeW)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(ringColor, style: StrokeStyle(lineWidth: strokeW, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.8), value: progress)

            if isOver {
                Circle()
                    .trim(from: 0, to: overProgress)
                    .stroke(ringColor.opacity(0.55),
                            style: StrokeStyle(lineWidth: strokeW + 2, lineCap: .round))
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.8), value: overProgress)
            }

            ringCenter
        }
        .frame(width: size, height: size)
        .animation(.easeInOut(duration: 0.4), value: ringColor)
    }

    /// Short, supportive label that reflects both progress and time of day.
    /// Always positive — overshoots are reframed, not scolded.
    private var label: String {
        let hour = Calendar.current.component(.hour, from: Date())

        // Over goal — keep it kind
        if pct > 1.20 { return "Big day — rest well" }
        if pct > 1.10 { return "A little extra today" }
        if pct > 1.05 { return "Just past target" }

        // On target band
        if pct >= 0.95 { return "Right on target 🎯" }

        // Approaching
        if pct >= 0.85 { return "Almost there" }
        if pct >= 0.70 { return hour < 18 ? "Save room for dinner" : "Closing in nicely" }

        // Mid-day
        if pct >= 0.45 {
            switch hour {
            case ..<11:  return "Strong start"
            case 11..<14: return "Steady pace"
            case 14..<18: return "Going well"
            default:      return "Plenty of room left"
            }
        }

        // Light eating
        if pct >= 0.15 {
            switch hour {
            case ..<11:  return "Easing in ☕️"
            case 11..<14: return "Light morning"
            case 14..<18: return "Lots of fuel ahead"
            default:      return "Room for one more"
            }
        }

        // Empty / very light
        switch hour {
        case ..<11:  return "Fresh canvas ✨"
        case 11..<14: return "Time to fuel up"
        case 14..<18: return "Don't forget to eat"
        default:      return "Quiet day so far"
        }
    }

    private var bigNumber: String {
        let delta = pct > 1.0 ? consumed - goal : goal - consumed
        return abs(delta).formatted(.number)
    }

    var ringCenter: some View {
        VStack(spacing: 0) {
            Text(label)
                .font(.system(size: 13, weight: pct >= 0.95 ? .semibold : .medium))
                .foregroundColor(pct >= 0.95 ? ringColor : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: 168)
                .padding(.bottom, 2)
                .animation(.easeInOut(duration: 0.4), value: ringColor)

            Text(bigNumber)
                .font(.system(size: 56, weight: .bold))
                .tracking(-2)
                .foregroundColor(pct >= 0.95 ? ringColor : .primary)
                .animation(.easeInOut(duration: 0.4), value: ringColor)

            HStack(spacing: 2) {
                Text(consumed.formatted(.number))
                    .font(.system(size: 13, weight: .semibold))
                Text("/ \(goal.formatted(.number)) kcal")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .tracking(0.4)
            }
            .padding(.top, 6)
        }
    }
}

// MARK: - CompactMacroRow (for the side-by-side compact card)

struct CompactMacroRow: View {
    let label: String
    let stat: MacroStat
    let color: Color

    private var pct: Double { min(1, Double(stat.grams) / Double(max(1, stat.goal))) }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline) {
                Text(LocalizedStringKey(label))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 1) {
                    Text("\(stat.grams)")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(-0.2)
                        .monospacedDigit()
                    Text("/\(stat.goal)g")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.06))
                        .frame(height: 3)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * pct, height: 3)
                        .animation(.spring(duration: 0.6), value: pct)
                }
            }
            .frame(height: 3)
        }
    }
}

// MARK: - MacroBarView

struct MacroBarView: View {
    let label: String
    let stat: MacroStat
    let color: Color

    private var progress: Double { min(1, Double(stat.grams) / Double(max(1, stat.goal))) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .lastTextBaseline) {
                Text(LocalizedStringKey(label))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(stat.goal)g")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .padding(.bottom, 6)

            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text("\(stat.grams)")
                    .font(.system(size: 18, weight: .semibold))
                    .tracking(-0.4)
                Text("g")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 6)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.06))
                        .frame(height: 4)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * progress, height: 4)
                        .animation(.spring(duration: 0.8), value: progress)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - ActivityCardView

struct ActivityCardView: View {
    let burned: Int
    let activities: [Activity]
    let connected: Bool
    let onConnect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Text("Calories burned")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(burned)")
                            .font(.system(size: 28, weight: .bold))
                            .tracking(-0.8)
                        Text(connected ? "kcal · today" : "kcal")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                healthBadge
            }

            if connected {
                if activities.isEmpty {
                    Text("No workouts recorded yet today.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    HStack(spacing: 6) {
                        ForEach(activities.prefix(3)) { ActivityTileView(activity: $0) }
                    }
                }
            } else {
                Button(action: onConnect) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "FF375F"))
                        Text("Connect Apple Health")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.tertiarySystemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .cardStyle()
    }

    var healthBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "heart.fill")
                .font(.system(size: 9))
                .foregroundColor(Color(hex: "FF375F"))
            Text(connected ? "HEALTH" : "OFF")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            Capsule()
                .fill(Color(UIColor.tertiarySystemBackground))
                .overlay(Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 1))
        )
    }
}

struct ActivityTileView: View {
    let activity: Activity

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(activity.emoji).font(.system(size: 18))
            Text(activity.type)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text("\(activity.kcal)")
                    .font(.system(size: 14, weight: .bold))
                    .tracking(-0.3)
                Text(" kcal")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            if !activity.duration.isEmpty {
                Text(activity.duration)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.tertiarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - FoodQualityCardView

struct FoodQualityCardView: View {
    let meals: [Meal]

    private var avg: Int {
        meals.isEmpty ? 0 : meals.map(\.quality).reduce(0, +) / meals.count
    }
    private var best: Meal?  { meals.max(by: { $0.quality < $1.quality }) }
    private var worst: Meal? { meals.min(by: { $0.quality < $1.quality }) }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 16) {
                QualityRingView(value: avg, size: 68, strokeW: 7)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Nutrition Score")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)

                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text("\(avg)")
                            .font(.system(size: 26, weight: .bold))
                            .tracking(-0.8)
                        Text("/ 100")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    let qc = qualityColor(avg)
                    HStack(spacing: 5) {
                        Circle().fill(qc).frame(width: 5, height: 5)
                        Text(meals.isEmpty ? "Log a meal to start" : qualityLabel(avg))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(qc)
                    }
                    .padding(.vertical, 3)
                    .padding(.horizontal, 9)
                    .background(Capsule().fill(qualityColor(avg).opacity(0.13)))
                    .padding(.top, 6)
                }
                Spacer()
            }

            if let b = best, let w = worst, meals.count > 1 {
                Divider()
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("BEST")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.tertiary)
                            .tracking(0.6)
                        Text("\(b.emoji) \(b.name)")
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Divider().frame(height: 32)
                    if w.quality >= 80 {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ALL CLEAN")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.tertiary)
                                .tracking(0.6)
                            Text("✨ Every meal scored high")
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)
                                .foregroundColor(Color(hex: "3DB46D"))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("NEEDS WORK")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.tertiary)
                                .tracking(0.6)
                            Text("\(w.emoji) \(w.name)")
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(18)
        .cardStyle()
    }
}

// MARK: - QualityRingView

struct QualityRingView: View {
    let value: Int
    var size: CGFloat = 64
    var strokeW: CGFloat = 7

    private var progress: Double { Double(value) / 100 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.06), lineWidth: strokeW)
                .frame(width: size, height: size)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(qualityColor(value), style: StrokeStyle(lineWidth: strokeW, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
            Text("\(value)")
                .font(.system(size: size > 50 ? 18 : 13, weight: .bold))
                .tracking(-0.4)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - MealRowView

struct MealRowView: View {
    let meal: Meal

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        colors: meal.gradient,
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 44, height: 44)
                    .overlay(Text(meal.emoji).font(.system(size: 22)))

                let qc = qualityColor(meal.quality)
                ZStack {
                    Circle()
                        .fill(qc)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle().stroke(Color(UIColor.systemBackground), lineWidth: 2)
                        )
                    Text("\(meal.quality)")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(-0.2)
                        .foregroundColor(.white)
                }
                .offset(x: 3, y: 3)
            }

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .lastTextBaseline) {
                    Text(LocalizedStringKey(meal.type))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .tracking(0.6)
                        .textCase(.uppercase)
                    Spacer()
                    HStack(alignment: .lastTextBaseline, spacing: 1) {
                        Text("\(meal.kcal)")
                            .font(.system(size: 15, weight: .semibold))
                            .tracking(-0.2)
                        Text(" kcal")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                Text(meal.name)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                    .padding(.top, 2)
                Text(meal.time)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 1)
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - BurnedSheetView

struct BurnedSheetView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var refreshing = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .lastTextBaseline) {
                Text("Calories burned")
                    .font(.system(size: 20, weight: .bold))
                    .tracking(-0.4)
                Spacer()
                Button("Done") { dismiss() }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)

            VStack(spacing: 8) {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(accentOrange)
                    Text("\(appState.caloriesBurnedToday)")
                        .font(.system(size: 64, weight: .bold))
                        .tracking(-2.4)
                        .monospacedDigit()
                    Text("kcal")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                if appState.healthKitAuthorized {
                    HStack(spacing: 5) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Color(hex: "FF375F"))
                        Text("FROM APPLE HEALTH")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(0.6)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4).padding(.horizontal, 10)
                    .background(Capsule().fill(Color(UIColor.tertiarySystemBackground)))
                }
            }
            .padding(.vertical, 20)

            ScrollView {
                if appState.activitiesToday.isEmpty {
                    Text("No activity recorded yet today.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .padding(.top, 12)
                } else {
                    VStack(spacing: 8) {
                        ForEach(appState.activitiesToday) { act in
                            BurnRowView(activity: act)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                }
            }

            Button {
                Task {
                    refreshing = true
                    await appState.refreshHealth()
                    refreshing = false
                }
            } label: {
                HStack(spacing: 6) {
                    if refreshing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    Text(refreshing ? "Refreshing…" : "Refresh from Apple Health")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(accentOrange)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: accentOrange.opacity(0.3), radius: 10, y: 3)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 28)
            .disabled(refreshing || !appState.healthKitAuthorized)
        }
    }
}

struct BurnRowView: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.tertiarySystemBackground))
                    .frame(width: 44, height: 44)
                Text(activity.emoji).font(.system(size: 22))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.type)
                    .font(.system(size: 14, weight: .semibold))
                if !activity.duration.isEmpty {
                    Text(activity.duration)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text("\(activity.kcal)")
                    .font(.system(size: 18, weight: .bold))
                    .tracking(-0.4)
                    .monospacedDigit()
                Text("kcal")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1))
        )
    }
}
