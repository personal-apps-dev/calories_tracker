import SwiftUI

// MARK: - DiaryView

struct DiaryView: View {
    @EnvironmentObject var appState: AppState
    @State private var expanded: Int = 0

    private var avgCalories: Int {
        let total = historyDays.map(\.consumed).reduce(0, +)
        return total / max(1, historyDays.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Diary")
                        .font(.system(size: 28, weight: .bold))
                        .tracking(-0.8)
                    Text("\(historyDays.count) days · 7-day avg \(avgCalories.formatted(.number)) kcal")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 18)

                VStack(spacing: 10) {
                    ForEach(Array(historyDays.enumerated()), id: \.offset) { i, day in
                        DayCardView(
                            day: day,
                            liveGoal: appState.goal,
                            isOpen: expanded == i,
                            onTap: { withAnimation(.spring(duration: 0.25)) { expanded = expanded == i ? -1 : i } }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 110)
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}

struct DayCardView: View {
    let day: DayRecord
    let liveGoal: Int
    let isOpen: Bool
    let onTap: () -> Void

    private var effectiveGoal: Int { day.storedGoal ?? liveGoal }
    private var over: Bool { day.consumed > effectiveGoal }
    private var pct: Double { min(1, Double(day.consumed) / Double(effectiveGoal)) }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 14) {
                    miniRing
                    dayInfo
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                        .animation(.spring(duration: 0.25), value: isOpen)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isOpen && !day.meals.isEmpty {
                Divider().padding(.leading, 74)
                VStack(spacing: 0) {
                    ForEach(day.meals) { meal in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(
                                    colors: meal.gradient,
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                                .frame(width: 36, height: 36)
                                .overlay(Text(meal.emoji).font(.system(size: 18)))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(meal.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .lineLimit(1)
                                Text("\(meal.type) · \(meal.time)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Text("\(meal.kcal)")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
        .cardStyle()
    }

    var miniRing: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.06), lineWidth: 4)
                .frame(width: 44, height: 44)
            Circle()
                .trim(from: 0, to: pct)
                .stroke(
                    over ? Color(hex: "E86A6A") : accentOrange,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 44, height: 44)
                .rotationEffect(.degrees(-90))
            Text("\(Int(pct * 100))")
                .font(.system(size: 11, weight: .bold))
        }
    }

    var dayInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(day.label)
                    .font(.system(size: 15, weight: .semibold))
                Text(day.date)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            HStack(spacing: 2) {
                Text(day.consumed.formatted(.number))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(over ? Color(hex: "E86A6A") : .primary)
                Text("/ \(effectiveGoal.formatted(.number)) kcal · \(day.mealCount) meals")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - TrendsView

struct TrendsView: View {
    @EnvironmentObject var appState: AppState
    @State private var range: RangeType = .week
    @State private var metric: MetricType = .calories

    enum RangeType: String, CaseIterable { case week = "Week", month = "Month", year = "Year" }
    enum MetricType: String, CaseIterable { case calories = "Calories", quality = "Quality" }

    private var entries: [TrendEntry] {
        switch range {
        case .week:  return weekTrends
        case .month: return monthTrends
        case .year:  return yearTrends
        }
    }

    private var rangeTitle: String {
        switch range {
        case .week:  return "Apr 24 – Apr 30"
        case .month: return "April 2026"
        case .year:  return "Last 12 months"
        }
    }

    private var avg: Int { entries.map(\.consumed).reduce(0, +) / max(1, entries.count) }
    private var avgQ: Int { entries.map(\.quality).reduce(0, +) / max(1, entries.count) }
    private var onGoal: Int { entries.filter { $0.consumed <= appState.goal }.count }
    private var onGoalPct: Int { Int(Double(onGoal) / Double(max(1, entries.count)) * 100) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                rangePicker
                statCards
                qualityHero
                metricToggle
                barChart
                macroDonut
            }
            .padding(.bottom, 110)
        }
        .background(Color(UIColor.systemBackground))
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Trends")
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.8)
            Text(rangeTitle)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 18)
    }

    var rangePicker: some View {
        HStack(spacing: 4) {
            ForEach(RangeType.allCases, id: \.self) { r in
                Button(r.rawValue) {
                    withAnimation(.spring(duration: 0.25)) { range = r }
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(range == r ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(range == r ? Color(UIColor.systemBackground) : Color.clear)
                        .shadow(color: .black.opacity(range == r ? 0.06 : 0), radius: 2, y: 1)
                )
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 14)
    }

    var statCards: some View {
        HStack(spacing: 10) {
            StatCardView(label: "Avg / day", value: avg.formatted(.number), sub: "kcal")
            StatCardView(label: "On goal",   value: "\(onGoalPct)%",        sub: "\(onGoal) of \(entries.count) days")
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 14)
    }

    var qualityHero: some View {
        HStack(spacing: 16) {
            QualityRingView(value: avgQ, size: 64, strokeW: 7)

            VStack(alignment: .leading, spacing: 2) {
                Text("Avg food quality")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("\(avgQ)")
                        .font(.system(size: 28, weight: .bold))
                        .tracking(-0.8)
                    Text("/ 100")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                let qc = qualityColor(avgQ)
                HStack(spacing: 5) {
                    Circle().fill(qc).frame(width: 5, height: 5)
                    Text(qualityLabel(avgQ))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(qc)
                }
                .padding(.vertical, 3).padding(.horizontal, 9)
                .background(Capsule().fill(qc.opacity(0.13)))
                .padding(.top, 6)
            }
            Spacer()
        }
        .padding(18)
        .cardStyle()
        .padding(.horizontal, 24)
        .padding(.bottom, 18)
    }

    var metricToggle: some View {
        HStack(spacing: 6) {
            ForEach(MetricType.allCases, id: \.self) { m in
                Button(m.rawValue) {
                    withAnimation(.spring(duration: 0.2)) { metric = m }
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(metric == m ? Color(UIColor.systemBackground) : .secondary)
                .padding(.vertical, 6)
                .padding(.horizontal, 14)
                .background(
                    Capsule()
                        .fill(metric == m ? Color.primary : Color.clear)
                        .overlay(Capsule().stroke(Color.primary.opacity(metric == m ? 0 : 0.15), lineWidth: 1))
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    var barChart: some View {
        VStack(spacing: 0) {
            HStack(alignment: .lastTextBaseline) {
                Text(metric == .calories ? "Daily calories" : "Daily quality score")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.4))
                        .frame(width: 10, height: 1.5)
                    Text(metric == .calories
                         ? "Goal \(appState.goal.formatted(.number))"
                         : "Target 75")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 14)

            BarChartView(
                entries: entries,
                metric: metric,
                goal: appState.goal,
                range: range
            )
            .frame(height: 140)
            .padding(.bottom, 8)

            // Labels
            let barGap: CGFloat = range == .month ? 2 : 8
            HStack(spacing: barGap) {
                ForEach(Array(entries.enumerated()), id: \.offset) { i, e in
                    Text(e.label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .opacity(showLabel(i, total: entries.count, range: range) ? 1 : 0)
                }
            }
        }
        .padding(18)
        .cardStyle()
        .padding(.horizontal, 24)
        .padding(.bottom, 22)
    }

    var macroDonut: some View {
        HStack(spacing: 18) {
            MacroDonutView()
            VStack(alignment: .leading, spacing: 10) {
                Text("Macro split")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.bottom, 2)
                ForEach([
                    ("Protein", 22, Color(hex: "5B8DEF")),
                    ("Carbs",   48, Color(hex: "F4B740")),
                    ("Fat",     30, Color(hex: "E86A6A")),
                ], id: \.0) { label, pct, color in
                    HStack(spacing: 8) {
                        Circle().fill(color).frame(width: 8, height: 8)
                        Text(label).font(.system(size: 13))
                        Spacer()
                        Text("\(pct)%")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            Spacer()
        }
        .padding(20)
        .cardStyle()
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    private func showLabel(_ i: Int, total: Int, range: RangeType) -> Bool {
        guard range == .month else { return true }
        return i == 0 || (i + 1) % 5 == 0 || i == total - 1
    }
}

struct BarChartView: View {
    let entries: [TrendEntry]
    let metric: TrendsView.MetricType
    let goal: Int
    let range: TrendsView.RangeType

    private var maxVal: Double {
        metric == .calories
            ? max(Double(goal), entries.map { Double($0.consumed) }.max() ?? 0) * 1.05
            : 100
    }
    private var targetLine: Double {
        metric == .calories ? Double(goal) : 75
    }
    private var barGap: CGFloat { range == .month ? 2 : 8 }
    private var cornerR: CGFloat { range == .month ? 2 : 5 }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Goal/target dashed line
                Rectangle()
                    .fill(Color.secondary.opacity(0.25))
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                    .offset(y: -geo.size.height * (targetLine / maxVal))

                // Bars
                HStack(alignment: .bottom, spacing: barGap) {
                    ForEach(Array(entries.enumerated()), id: \.offset) { i, e in
                        let val = metric == .calories ? Double(e.consumed) : Double(e.quality)
                        let fraction = val / maxVal
                        let isOver = metric == .calories && e.consumed > goal
                        let color: Color = metric == .calories
                            ? (isOver ? Color(hex: "E86A6A") : accentOrange)
                            : qualityColor(e.quality)

                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            RoundedRectangle(cornerRadius: cornerR)
                                .fill(color)
                                .frame(height: max(3, geo.size.height * fraction))
                                .opacity(i == entries.count - 1 ? 1 : 0.88)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(duration: 0.4), value: metric)
            .animation(.spring(duration: 0.4), value: range)
        }
    }
}

struct MacroDonutView: View {
    private let segments: [(Double, Color)] = [
        (0.22, Color(hex: "5B8DEF")),
        (0.48, Color(hex: "F4B740")),
        (0.30, Color(hex: "E86A6A")),
    ]
    private let r: CGFloat = 36
    private let stroke: CGFloat = 12

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.06), lineWidth: stroke)
                .frame(width: r * 2, height: r * 2)

            ForEach(Array(segments.enumerated()), id: \.offset) { i, seg in
                let offset = segments.prefix(i).map(\.0).reduce(0, +)
                Circle()
                    .trim(from: offset, to: offset + seg.0 - 0.01)
                    .stroke(seg.1, style: StrokeStyle(lineWidth: stroke, lineCap: .butt))
                    .frame(width: r * 2, height: r * 2)
                    .rotationEffect(.degrees(-90))
            }
        }
        .frame(width: 88, height: 88)
    }
}

struct StatCardView: View {
    let label: String
    let value: String
    let sub: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 26, weight: .bold)).tracking(-0.8).monospacedDigit()
                .padding(.top, 2)
            Text(sub).font(.system(size: 11)).foregroundStyle(.tertiary).padding(.top, 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .cardStyle(radius: 18)
    }
}

// MARK: - ProfileView

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showGoalSheet: Bool
    @State private var showAPIKeyField = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Profile")
                    .font(.system(size: 28, weight: .bold))
                    .tracking(-0.8)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 22)

                avatarCard

                ProfileSection(label: "Goals") {
                    ProfileRow(icon: "🎯", label: "Daily calorie goal",
                               value: "\(appState.goal.formatted(.number)) kcal") {
                        showGoalSheet = true
                    }
                    ProfileRow(icon: "🥩", label: "Protein target", value: "140g") {}
                    ProfileRow(icon: "⚖️", label: "Weight goal", value: "−4.5 kg", isLast: true) {}
                }

                ProfileSection(label: "Preferences") {
                    ProfileRow(icon: appState.isDark ? "🌙" : "☀️", label: "Dark mode",
                               value: appState.isDark ? "On" : "Off") {
                        appState.isDark.toggle()
                    }
                    ProfileRow(icon: "🔔", label: "Notifications", value: "3 enabled") {}
                    ProfileRow(icon: "🔗", label: "Apple Health", value: "Connected", isLast: true) {}
                }

                ProfileSection(label: "AI Analysis") {
                    ProfileRow(icon: "🔑", label: "Claude API Key",
                               value: appState.claudeApiKey.isEmpty ? "Not set" : "••••••••") {
                        withAnimation { showAPIKeyField.toggle() }
                    }
                    if showAPIKeyField {
                        VStack(spacing: 0) {
                            Divider()
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Paste your Anthropic API key")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                SecureField("sk-ant-...", text: $appState.claudeApiKey)
                                    .font(.system(size: 14, design: .monospaced))
                                    .textContentType(.password)
                                    .autocorrectionDisabled()
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(UIColor.tertiarySystemBackground))
                                    )
                                Text("Used only for food photo analysis. Never shared.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(16)
                        }
                    }
                    ProfileRow(icon: "✨", label: "Analysis quality", value: "claude-opus-4-7",
                               isLast: true) {}
                }

                ProfileSection(label: "About") {
                    ProfileRow(icon: "❤️", label: "Rate the app") {}
                    ProfileRow(icon: "📄", label: "Privacy") {}
                    ProfileRow(icon: "🚪", label: "Sign out", isDanger: true, isLast: true) {}
                }

                Text("Version 1.0.0")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    .padding(.bottom, 110)
            }
        }
        .background(Color(UIColor.systemBackground))
    }

    var avatarCard: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(LinearGradient(
                    colors: [accentOrange, Color(hex: "5B8DEF")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 64, height: 64)
                .overlay(
                    Text(String(appState.userName.prefix(1)).uppercased())
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(appState.userName)
                    .font(.system(size: 18, weight: .bold))
                    .tracking(-0.4)
                Text("Member since Jan 2026")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Text("\u{2022} **12** day streak")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text("\u{2022} **148** meals logged")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .cardStyle()
        .padding(.horizontal, 16)
        .padding(.bottom, 22)
    }
}

struct ProfileSection<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(0.6)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content()
            }
            .cardStyle()
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 18)
    }
}

struct ProfileRow: View {
    let icon: String
    let label: String
    var value: String? = nil
    var isDanger: Bool = false
    var isLast: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 12) {
                Text(icon)
                    .font(.system(size: 16))
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(UIColor.tertiarySystemBackground))
                    )

                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isDanger ? Color(hex: "E86A6A") : .primary)

                Spacer()

                if let value {
                    Text(value)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if !isLast {
                Divider().padding(.leading, 60)
            }
        }
    }
}

// MARK: - GoalSheetView

struct GoalSheetView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var draft: Int = 0

    private let min = 1000
    private let max = 4000
    private let presets = [1500, 1800, 2000, 2200, 2500, 2800]

    var pct: Double { Double(draft - min) / Double(max - min) }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 14)
                .padding(.bottom, 18)

            HStack(alignment: .lastTextBaseline) {
                Text("Daily calorie goal")
                    .font(.system(size: 20, weight: .bold))
                    .tracking(-0.4)
                Spacer()
                Button("Cancel") { dismiss() }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)

            Text("Set the target you want to hit each day.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 4)
                .padding(.bottom, 24)

            // Stepper
            HStack(spacing: 18) {
                StepBtn(sfName: "minus") { draft = Swift.max(min, draft - 50) }

                VStack(spacing: 4) {
                    Text(draft.formatted(.number))
                        .font(.system(size: 56, weight: .bold))
                        .tracking(-2.4)
                        .monospacedDigit()
                        .animation(.spring(duration: 0.2), value: draft)
                    Text("KCAL / DAY")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .tracking(0.6)
                }
                .frame(minWidth: 140)

                StepBtn(sfName: "plus") { draft = Swift.min(max, draft + 50) }
            }
            .padding(.bottom, 22)

            // Slider
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.06))
                            .frame(height: 4)
                            .frame(maxHeight: .infinity)
                        Capsule()
                            .fill(accentOrange)
                            .frame(width: max(4, geo.size.width * pct), height: 4)
                            .frame(maxHeight: .infinity, alignment: .center)
                            .animation(.interactiveSpring(), value: pct)
                        // Thumb
                        Circle()
                            .fill(.white)
                            .overlay(Circle().stroke(accentOrange, lineWidth: 2))
                            .frame(width: 20, height: 20)
                            .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
                            .offset(x: max(0, geo.size.width * pct - 10))
                            .animation(.interactiveSpring(), value: pct)
                        // Hidden slider for touch input
                        Slider(value: Binding(
                            get: { Double(draft) },
                            set: { draft = Int($0 / 50) * 50 }
                        ), in: Double(min)...Double(max), step: 50)
                        .opacity(0.015)
                    }
                }
                .frame(height: 28)

                HStack {
                    Text("\(min.formatted(.number))")
                    Spacer()
                    Text("\(max.formatted(.number))")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 22)

            // Presets
            Text("QUICK PRESETS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                ForEach(presets, id: \.self) { p in
                    Button(p.formatted(.number)) {
                        withAnimation(.spring(duration: 0.2)) { draft = p }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(draft == p ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(draft == p ? accentOrange : Color(UIColor.secondarySystemBackground))
                            .overlay(
                                Capsule().stroke(
                                    draft == p ? accentOrange : Color.primary.opacity(0.08),
                                    lineWidth: 1
                                )
                            )
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)

            Button(action: {
                appState.goal = draft
                dismiss()
            }) {
                Text("Save goal")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(accentOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: accentOrange.opacity(0.4), radius: 12, y: 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear { draft = appState.goal }
    }
}

struct StepBtn: View {
    let sfName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: sfName)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color(UIColor.secondarySystemBackground))
                        .overlay(Circle().stroke(Color.primary.opacity(0.08), lineWidth: 1))
                )
        }
        .foregroundColor(.primary)
    }
}
