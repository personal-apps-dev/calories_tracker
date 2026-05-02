import SwiftUI

struct MealDetailView: View {
    let meal: LoggedMeal
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    @State private var showRefine = false
    @State private var showDeleteConfirm = false

    /// Latest version of the meal from AppState, in case it was edited
    /// while the sheet is open. Falls back to the seed value.
    private var live: LoggedMeal {
        appState.loggedMeals.first { $0.id == meal.id } ?? meal
    }

    private var factors: [QualityFactor] {
        qualityFactors(kcal: live.kcal, protein: live.protein, carbs: live.carbs, fat: live.fat)
    }

    private var timeLabel: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: live.timestamp)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    headerCard
                    macrosCard
                    scoreCard
                    factorsCard
                    actionsCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("Meal details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            .sheet(isPresented: $showRefine) {
                RefineMealSheet(base: live)
            }
            .alert("Delete this meal?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    appState.deleteMeal(id: live.id)
                    dismiss()
                }
            } message: {
                Text("This removes \(live.kcal) kcal from today's totals. You can't undo this.")
            }
        }
    }

    // MARK: Actions

    var actionsCard: some View {
        VStack(spacing: 8) {
            Button {
                showRefine = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.bubble.fill")
                    Text("Add to / refine this meal")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(accentOrange)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: accentOrange.opacity(0.35), radius: 10, y: 3)
            }

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("Delete meal")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(Color(hex: "E86A6A"))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.tertiarySystemBackground))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1))
                )
            }
        }
    }

    // MARK: Header

    var headerCard: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: gradientFor(type: live.type),
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 64, height: 64)
                .overlay(Text(live.emoji).font(.system(size: 32)))

            VStack(alignment: .leading, spacing: 3) {
                Text(live.type.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(.secondary)
                Text(live.name)
                    .font(.system(size: 17, weight: .bold))
                    .tracking(-0.4)
                    .lineLimit(2)
                Text(timeLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: Macros

    var macrosCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("🍽 Macros")

            HStack(alignment: .lastTextBaseline) {
                Text("\(live.kcal)")
                    .font(.system(size: 36, weight: .bold))
                    .tracking(-1)
                    .monospacedDigit()
                Text("kcal total")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                MacroLineView(label: "Protein", grams: live.protein, totalKcal: live.kcal, gPerKcal: 4, color: Color(hex: "5B8DEF"))
                MacroLineView(label: "Carbs",   grams: live.carbs,   totalKcal: live.kcal, gPerKcal: 4, color: Color(hex: "F4B740"))
                MacroLineView(label: "Fat",     grams: live.fat,     totalKcal: live.kcal, gPerKcal: 9, color: Color(hex: "E86A6A"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: Score hero

    var scoreCard: some View {
        let qc = qualityColor(live.quality)
        return HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.06), lineWidth: 9)
                    .frame(width: 92, height: 92)
                Circle()
                    .trim(from: 0, to: Double(live.quality) / 100)
                    .stroke(qc, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .frame(width: 92, height: 92)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(live.quality)")
                        .font(.system(size: 26, weight: .bold))
                        .tracking(-0.6)
                    Text("/100")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Nutrition Score")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(qualityLabel(live.quality))
                    .font(.system(size: 20, weight: .bold))
                    .tracking(-0.4)
                    .foregroundColor(qc)
                Text(scoreBlurb)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var scoreBlurb: String {
        switch live.quality {
        case 80...:  return "A high-quality choice — keep it up."
        case 60..<80: return "Solid meal with a few things to watch."
        case 45..<60: return "Mixed bag — see the breakdown below."
        default:     return "Heavy on the body — consider lighter options next time."
        }
    }

    // MARK: Why this score

    var factorsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("⚖️ Why this score")

            ForEach(factors) { f in
                FactorRow(factor: f)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func sectionLabel(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
            .tracking(0.4)
    }
}

// MARK: - Macro line

struct MacroLineView: View {
    let label: String
    let grams: Int
    let totalKcal: Int
    let gPerKcal: Int   // 4 for protein/carbs, 9 for fat
    let color: Color

    private var pct: Int {
        guard totalKcal > 0 else { return 0 }
        return Int((Double(grams * gPerKcal) / Double(totalKcal) * 100).rounded())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .lastTextBaseline) {
                Circle().fill(color).frame(width: 7, height: 7)
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                Text("\(grams)g")
                    .font(.system(size: 13, weight: .semibold))
                    .monospacedDigit()
                Text("· \(pct)%")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.06))
                        .frame(height: 5)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * Double(pct) / 100, height: 5)
                }
            }
            .frame(height: 5)
        }
    }
}

// MARK: - Factor row

struct FactorRow: View {
    let factor: QualityFactor

    private var iconName: String {
        switch factor.impact {
        case .positive: return "checkmark.circle.fill"
        case .neutral:  return "circle.fill"
        case .negative: return "exclamationmark.triangle.fill"
        }
    }
    private var tint: Color {
        switch factor.impact {
        case .positive: return Color(hex: "3DB46D")
        case .neutral:  return Color.secondary
        case .negative: return Color(hex: "E86A6A")
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 18, height: 18)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(factor.title)
                        .font(.system(size: 14, weight: .semibold))
                    Text(factor.category.uppercased())
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(0.4)
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(Capsule().fill(Color.primary.opacity(0.06)))
                }
                Text(factor.detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - RefineMealSheet

struct RefineMealSheet: View {
    let base: LoggedMeal

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var text: String = ""
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @FocusState private var focused: Bool

    private let examples = [
        "Plus a glass of milk",
        "Forgot a side of fries",
        "Add a tablespoon of olive oil",
        "Replace rice with quinoa",
        "Double the portion size",
    ]

    private var canSubmit: Bool {
        !isAnalyzing &&
        text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                // Current meal summary
                VStack(alignment: .leading, spacing: 6) {
                    Text("CURRENT MEAL")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .tracking(0.5)
                    HStack(spacing: 10) {
                        Text(base.emoji).font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(base.name)
                                .font(.system(size: 14, weight: .semibold))
                                .lineLimit(1)
                            Text("\(base.kcal) kcal · \(base.protein)P / \(base.carbs)C / \(base.fat)F")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Spacer(minLength: 0)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle(radius: 14)

                Text("What did you add or change? We'll re-evaluate the whole meal.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("e.g. \"Plus a glass of orange juice and a slice of toast\"")
                            .font(.system(size: 15))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                    }
                    TextEditor(text: $text)
                        .font(.system(size: 15))
                        .focused($focused)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                }
                .frame(minHeight: 130)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1))
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(examples, id: \.self) { ex in
                            Button {
                                text = ex
                            } label: {
                                Text(ex)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(
                                        Capsule().fill(Color(UIColor.tertiarySystemBackground))
                                            .overlay(Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 1))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if let err = errorMessage {
                    Text(err)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "E86A6A"))
                }

                Spacer(minLength: 0)

                Button {
                    Task { await submit() }
                } label: {
                    HStack(spacing: 8) {
                        if isAnalyzing {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(isAnalyzing ? "Re-analyzing…" : "Re-analyze")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(canSubmit ? accentOrange : Color.secondary.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: canSubmit ? accentOrange.opacity(0.4) : .clear, radius: 12, y: 4)
                }
                .disabled(!canSubmit)
            }
            .padding(20)
            .navigationTitle("Refine meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(isAnalyzing)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { focused = true }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isAnalyzing)
    }

    private func submit() async {
        guard !appState.claudeApiKey.isEmpty else {
            errorMessage = "Add your Claude API key in Profile first."
            return
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else { return }

        errorMessage = nil
        isAnalyzing = true
        do {
            let result = try await ClaudeService.shared.refineFood(
                base: base,
                additions: trimmed,
                apiKey: appState.claudeApiKey,
                language: appState.appLanguage
            )
            await MainActor.run {
                appState.updateMeal(id: base.id, with: result)
                isAnalyzing = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isAnalyzing = false
            }
        }
    }
}
