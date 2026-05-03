import SwiftUI

// MARK: - Insight model

enum InsightKind { case strong, neutral, watch, action }

struct NutritionInsight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
    let kind: InsightKind

    var tint: Color {
        switch kind {
        case .strong:  return Color(hex: "3DB46D")
        case .neutral: return .secondary
        case .watch:   return Color(hex: "F4B740")
        case .action:  return Color(hex: "5B8DEF")
        }
    }
}

// MARK: - Heuristics

struct DayStats {
    let meals: [LoggedMeal]
    let goal: Int
    let burned: Int

    var totalKcal: Int    { meals.map(\.kcal).reduce(0, +) }
    var totalProtein: Int { meals.map(\.protein).reduce(0, +) }
    var totalCarbs: Int   { meals.map(\.carbs).reduce(0, +) }
    var totalFat: Int     { meals.map(\.fat).reduce(0, +) }
    var avgQuality: Int {
        meals.isEmpty ? 0 : meals.map(\.quality).reduce(0, +) / meals.count
    }
    var effectiveGoal: Int { goal + burned }

    var proteinPctOfCals: Double {
        totalKcal > 0 ? Double(totalProtein * 4) / Double(totalKcal) : 0
    }
    var carbsPctOfCals: Double {
        totalKcal > 0 ? Double(totalCarbs * 4) / Double(totalKcal) : 0
    }
    var fatPctOfCals: Double {
        totalKcal > 0 ? Double(totalFat * 9) / Double(totalKcal) : 0
    }
}

func generateInsights(stats: DayStats) -> [NutritionInsight] {
    let s = stats
    guard !s.meals.isEmpty else { return [] }

    var out: [NutritionInsight] = []

    let pct = Double(s.totalKcal) / Double(max(1, s.effectiveGoal))
    if pct >= 0.95 && pct <= 1.05 {
        out.append(.init(icon: "🎯",
                         title: "Right on target",
                         detail: "\(s.totalKcal) of \(s.effectiveGoal) kcal — nicely paced.",
                         kind: .strong))
    } else if pct < 0.5 {
        out.append(.init(icon: "🍽️",
                         title: "Light day so far",
                         detail: "\(s.totalKcal) kcal — plenty of room for a substantial meal.",
                         kind: .neutral))
    } else if pct > 1.15 {
        out.append(.init(icon: "📈",
                         title: "Above today's target",
                         detail: "\(s.totalKcal) of \(s.effectiveGoal) — fine occasionally; lean lighter tomorrow.",
                         kind: .watch))
    } else if pct >= 0.5 && pct < 0.95 {
        out.append(.init(icon: "⚖️",
                         title: "Steady pace",
                         detail: "\(s.totalKcal) of \(s.effectiveGoal) kcal — on track for a normal day.",
                         kind: .neutral))
    }

    let pPct = Int((s.proteinPctOfCals * 100).rounded())
    if s.proteinPctOfCals >= 0.25 {
        out.append(.init(icon: "💪",
                         title: "Strong protein",
                         detail: "\(s.totalProtein)g — \(pPct)% of calories. Good for satiety and recovery.",
                         kind: .strong))
    } else if s.proteinPctOfCals < 0.15 {
        out.append(.init(icon: "🥩",
                         title: "Could use more protein",
                         detail: "Only \(s.totalProtein)g (\(pPct)%). Aim for ~25–30% of calories.",
                         kind: .action))
    }

    let fPct = Int((s.fatPctOfCals * 100).rounded())
    if s.fatPctOfCals > 0.45 {
        out.append(.init(icon: "🛢️",
                         title: "Fat-heavy day",
                         detail: "\(fPct)% of calories from fat — try leaner cuts or less oil next.",
                         kind: .watch))
    } else if s.fatPctOfCals < 0.20 && s.totalKcal > 600 {
        out.append(.init(icon: "🥑",
                         title: "Very lean day",
                         detail: "Only \(fPct)% from fat — a small handful of nuts or olive oil could help.",
                         kind: .action))
    }

    if s.avgQuality >= 80 {
        out.append(.init(icon: "✨",
                         title: "Clean choices",
                         detail: "Average score \(s.avgQuality)/100 — keep it up.",
                         kind: .strong))
    } else if s.avgQuality < 50 && s.meals.count >= 2 {
        out.append(.init(icon: "🥗",
                         title: "Lean toward whole foods",
                         detail: "Today averages \(s.avgQuality)/100. Swap one item for fruit, veg, or lean protein.",
                         kind: .action))
    }

    if s.meals.count == 1 {
        out.append(.init(icon: "⏰",
                         title: "Just one meal logged",
                         detail: "Spreading meals through the day keeps energy steady.",
                         kind: .action))
    } else if s.meals.count >= 6 {
        out.append(.init(icon: "🔢",
                         title: "Lots of small meals",
                         detail: "\(s.meals.count) entries — good for steady blood sugar.",
                         kind: .neutral))
    }

    return out
}

// MARK: - NutritionSummarySheet

struct NutritionSummarySheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var aiSummary: String?
    @State private var aiLoading = false
    @State private var aiError: String?

    private var todayMeals: [LoggedMeal] {
        let cal = Calendar.current
        return appState.loggedMeals
            .filter { cal.isDateInToday($0.timestamp) }
            .sorted { $0.timestamp < $1.timestamp }
    }

    private var stats: DayStats {
        DayStats(meals: todayMeals,
                 goal: appState.goal,
                 burned: appState.caloriesBurnedToday)
    }

    private var insights: [NutritionInsight] { generateInsights(stats: stats) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    headerCard
                    if !todayMeals.isEmpty {
                        macroCard
                        mealsCard
                        if !insights.isEmpty {
                            insightsCard
                        }
                        aiCard
                    } else {
                        emptyCard
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("Today's nutrition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
    }

    // MARK: Header

    var headerCard: some View {
        let avg = stats.avgQuality
        let qc = qualityColor(avg)
        return HStack(spacing: 16) {
            QualityRingView(value: avg, size: 84, strokeW: 9)
            VStack(alignment: .leading, spacing: 4) {
                Text("Nutrition Score")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(avg)")
                        .font(.system(size: 32, weight: .bold))
                        .tracking(-0.8)
                    Text("/ 100")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Text(todayMeals.isEmpty ? "Nothing logged yet" : qualityLabel(avg))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(qc)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: Macros + calories

    var macroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("📊 Today so far")

            HStack(alignment: .lastTextBaseline, spacing: 5) {
                Text("\(stats.totalKcal)")
                    .font(.system(size: 32, weight: .bold))
                    .tracking(-0.8)
                    .monospacedDigit()
                Text("kcal · goal \(stats.effectiveGoal)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                summaryMacroRow(label: "Protein", grams: stats.totalProtein,
                                pct: stats.proteinPctOfCals,
                                color: Color(hex: "5B8DEF"))
                summaryMacroRow(label: "Carbs", grams: stats.totalCarbs,
                                pct: stats.carbsPctOfCals,
                                color: Color(hex: "F4B740"))
                summaryMacroRow(label: "Fat", grams: stats.totalFat,
                                pct: stats.fatPctOfCals,
                                color: Color(hex: "E86A6A"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func summaryMacroRow(label: String, grams: Int, pct: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .lastTextBaseline) {
                Circle().fill(color).frame(width: 7, height: 7)
                Text(LocalizedStringKey(label)).font(.system(size: 13, weight: .medium))
                Spacer()
                Text("\(grams)g")
                    .font(.system(size: 13, weight: .semibold))
                    .monospacedDigit()
                Text("· \(Int((pct * 100).rounded()))%")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.06)).frame(height: 4)
                    Capsule().fill(color).frame(width: geo.size.width * pct, height: 4)
                }
            }
            .frame(height: 4)
        }
    }

    // MARK: Meals list

    var mealsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("🍽️ Meals")
            VStack(spacing: 0) {
                ForEach(Array(todayMeals.enumerated()), id: \.element.id) { i, lm in
                    HStack(spacing: 12) {
                        Text(lm.emoji).font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lm.name)
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)
                            Text("\(lm.kcal) kcal · \(lm.protein)P / \(lm.carbs)C / \(lm.fat)F")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                                .monospacedDigit()
                        }
                        Spacer(minLength: 0)
                        ZStack {
                            Circle()
                                .fill(qualityColor(lm.quality))
                                .frame(width: 26, height: 26)
                            Text("\(lm.quality)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .monospacedDigit()
                        }
                    }
                    .padding(.vertical, 10)
                    if i < todayMeals.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: Insights

    var insightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("💡 Insights")
            VStack(spacing: 10) {
                ForEach(insights) { insight in
                    InsightRow(insight: insight)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: AI summary

    var aiCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("✨ AI deep-dive")

            if let summary = aiSummary {
                Text(summary)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Regenerate") {
                    Task { await runAISummary() }
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(accentOrange)
                .disabled(aiLoading)
            } else if aiLoading {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.8)
                    Text("Analyzing your day…")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Ask Claude to read your day and write a personalized recap with concrete next steps. One API call.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    Task { await runAISummary() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Generate AI summary")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 9)
                    .padding(.horizontal, 14)
                    .background(accentOrange)
                    .clipShape(Capsule())
                    .shadow(color: accentOrange.opacity(0.3), radius: 6, y: 2)
                }
                .disabled(appState.claudeApiKey.isEmpty)
            }

            if let err = aiError {
                Text(err).font(.system(size: 11)).foregroundColor(Color(hex: "E86A6A"))
            }
            if appState.claudeApiKey.isEmpty {
                Text("Add your Claude API key in Profile to enable this.")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func runAISummary() async {
        guard !appState.claudeApiKey.isEmpty else {
            aiError = "Add your Claude API key in Profile."
            return
        }
        aiError = nil
        aiLoading = true
        defer { aiLoading = false }

        do {
            let text = try await ClaudeService.shared.dailyNutritionSummary(
                stats: stats,
                language: appState.appLanguage,
                userName: appState.userName,
                apiKey: appState.claudeApiKey
            )
            aiSummary = text
        } catch {
            aiError = error.localizedDescription
        }
    }

    // MARK: Empty

    var emptyCard: some View {
        VStack(spacing: 10) {
            Text("📷").font(.system(size: 38))
            Text("No meals logged today")
                .font(.system(size: 16, weight: .semibold))
            Text("Snap or describe a meal to start your nutrition recap.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private func sectionLabel(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
            .tracking(0.4)
    }
}

// MARK: - InsightRow

struct InsightRow: View {
    let insight: NutritionInsight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(insight.icon)
                .font(.system(size: 20))
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(insight.tint.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(insight.tint == .secondary ? .primary : insight.tint)
                Text(insight.detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}
