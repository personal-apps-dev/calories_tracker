import SwiftUI

// MARK: - HomeView

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showGoalSheet: Bool

    private var avgQuality: Int {
        let total = todayMeals.map(\.quality).reduce(0, +)
        return total / max(1, todayMeals.count)
    }

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
                macroSection
                activitySection
                qualitySection
                mealsSection
            }
            .padding(.bottom, 110)
        }
        .background(Color(UIColor.systemBackground))
    }

    // MARK: Header

    var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateString)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Hey, \(appState.userName) 👋")
                    .font(.system(size: 28, weight: .bold))
                    .tracking(-0.8)
            }
            Spacer()
            Circle()
                .fill(LinearGradient(
                    colors: [accentOrange, Color(hex: "5B8DEF")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(appState.userName.prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                )
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: Streak pill

    var streakPill: some View {
        HStack(spacing: 6) {
            Text("🔥").font(.system(size: 14))
            Text("\(todayStreak) day streak")
                .font(.system(size: 12, weight: .semibold))
        }
        .padding(.vertical, 5)
        .padding(.leading, 10)
        .padding(.trailing, 12)
        .background(
            Capsule()
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 1))
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 18)
    }

    // MARK: Ring + goal button

    var ringSection: some View {
        VStack(spacing: 14) {
            CalorieRingView(
                consumed: todayConsumed,
                goal: appState.goal,
                quality: avgQuality
            )
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
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.bottom, 24)
    }

    // MARK: Macros

    var macroSection: some View {
        HStack(spacing: 24) {
            MacroBarView(label: "Protein", stat: todayProtein, color: Color(hex: "5B8DEF"))
            MacroBarView(label: "Carbs",   stat: todayCarbs,   color: Color(hex: "F4B740"))
            MacroBarView(label: "Fat",     stat: todayFat,     color: Color(hex: "E86A6A"))
        }
        .padding(18)
        .cardStyle()
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    // MARK: Activity

    var activitySection: some View {
        ActivityCardView(burned: todayCaloriesBurned, activities: todayActivities)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
    }

    // MARK: Quality

    var qualitySection: some View {
        FoodQualityCardView(meals: todayMeals)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
    }

    // MARK: Meals list

    var mealsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today's meals")
                    .font(.system(size: 18, weight: .bold))
                    .tracking(-0.4)
                Spacer()
                Text("See all")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(accentOrange)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 0) {
                ForEach(Array(todayMeals.enumerated()), id: \.offset) { i, meal in
                    MealRowView(meal: meal)
                    if i < todayMeals.count - 1 {
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

// MARK: - CalorieRingView

struct CalorieRingView: View {
    let consumed: Int
    let goal: Int
    let quality: Int

    private let size: CGFloat = 220
    private let strokeW: CGFloat = 14

    private var over: Bool { consumed > goal }
    private var progress: Double { min(1, Double(consumed) / Double(goal)) }
    private var overProgress: Double { over ? min(1, Double(consumed - goal) / Double(goal)) : 0 }
    private var ringColor: Color { over ? Color(hex: "E86A6A") : accentOrange }

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

            if over {
                Circle()
                    .trim(from: 0, to: overProgress)
                    .stroke(ringColor.opacity(0.55), style: StrokeStyle(lineWidth: strokeW + 2, lineCap: .round))
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.8), value: overProgress)
            }

            ringCenter
        }
        .frame(width: size, height: size)
    }

    var ringCenter: some View {
        VStack(spacing: 0) {
            Text(over ? "over by" : "remaining")
                .font(.system(size: 13, weight: over ? .semibold : .medium))
                .foregroundColor(over ? Color(hex: "E86A6A") : .secondary)
                .padding(.bottom, 2)

            Text(abs(goal - consumed).formatted(.number))
                .font(.system(size: 56, weight: .bold))
                .tracking(-2)
                .foregroundColor(over ? Color(hex: "E86A6A") : .primary)

            HStack(spacing: 2) {
                Text(consumed.formatted(.number))
                    .font(.system(size: 13, weight: .semibold))
                Text("/ \(goal.formatted(.number)) kcal")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .tracking(0.4)
            }
            .padding(.top, 6)

            qualityPill.padding(.top, 8)
        }
    }

    var qualityPill: some View {
        let qc = qualityColor(quality)
        return HStack(spacing: 5) {
            ZStack {
                Circle().fill(qc).frame(width: 18, height: 18)
                Text("\(quality)")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(-0.2)
                    .foregroundColor(.white)
            }
            Text("calories quality")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(qc)
                .tracking(0.2)
        }
        .padding(.vertical, 3)
        .padding(.leading, 4)
        .padding(.trailing, 9)
        .background(Capsule().fill(qc.opacity(0.12)))
    }
}

// MARK: - MacroBarView

struct MacroBarView: View {
    let label: String
    let stat: MacroStat
    let color: Color

    private var progress: Double { min(1, Double(stat.grams) / Double(stat.goal)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .lastTextBaseline) {
                Text(label)
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
                        Text("kcal · today")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "FF375F"))
                    Text("HEALTH")
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

            HStack(spacing: 6) {
                ForEach(activities) { ActivityTileView(activity: $0) }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .cardStyle()
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
            Text(activity.duration)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
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
        meals.map(\.quality).reduce(0, +) / max(1, meals.count)
    }
    private var best: Meal?  { meals.max(by: { $0.quality < $1.quality }) }
    private var worst: Meal? { meals.min(by: { $0.quality < $1.quality }) }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 16) {
                QualityRingView(value: avg, size: 68, strokeW: 7)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Avg food quality")
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
                        Text(qualityLabel(avg))
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

            if let b = best, let w = worst {
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
                    Text(meal.type.uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .tracking(0.6)
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
