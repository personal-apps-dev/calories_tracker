import SwiftUI

struct MealDetailView: View {
    let meal: LoggedMeal
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    /// Single sheet selector — SwiftUI gets unreliable when multiple
    /// `.sheet(isPresented:)` modifiers stack on one view, so we route
    /// all child sheets through one `.sheet(item:)`.
    private enum ActiveSheet: String, Identifiable {
        case refine, edit, schedule
        var id: String { rawValue }
    }
    @State private var activeSheet: ActiveSheet?
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
                    if !live.items.isEmpty {
                        ingredientsCard
                    }
                    scoreCard
                    feelingCard
                    factorsCard
                    actionsCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color.niboCream)
            .navigationTitle("Meal details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
        // Sheet + alert attached to the *root* of body, not inside the
        // NavigationStack. iOS 16/17 has a quirk where a sheet attached
        // inside a NavigationStack that itself sits inside a parent
        // sheet can dismiss the parent on present — the activeSheet
        // change there propagates as a dismissal. Hoisting this up
        // to the body root makes the inner presentation independent
        // and keeps MealDetailView on screen behind it.
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .refine:
                RefineMealSheet(base: live)
            case .edit:
                EditMealSheet(base: live)
            case .schedule:
                ScheduleMealSheet(base: live)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
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

    // MARK: Feeling rating

    var feelingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("💭 How did this meal make you feel?")

            HStack(spacing: 10) {
                ForEach([(1, "😩"), (2, "😕"), (3, "😐"), (4, "🙂"), (5, "⚡")], id: \.0) { rating, emoji in
                    let isPicked = (live.feelingRating == rating)
                    Button {
                        appState.setFeelingRating(isPicked ? nil : rating, for: live.id)
                    } label: {
                        Text(emoji)
                            .font(.system(size: 26))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isPicked
                                          ? accentOrange.opacity(0.18)
                                          : Color.niboInset)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(isPicked ? accentOrange : Color.primary.opacity(0.06), lineWidth: 1.5)
                                    )
                            )
                            .saturation(isPicked || live.feelingRating == nil ? 1 : 0.4)
                            .opacity(isPicked || live.feelingRating == nil ? 1 : 0.55)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Tap how you felt 1–2 hours after eating. Over time we'll show which meals leave you feeling best.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: Actions

    /// Defers the state change a tick so SwiftUI's tap handling and any
    /// in-flight parent-sheet animations don't collide with the inner
    /// sheet presentation. Without this, presenting Edit / Refine /
    /// Schedule from MealDetailView right after a photo log can race
    /// the photo's fullScreenCover dismissal and make MealDetailView
    /// itself dismiss instead.
    private func present(_ sheet: ActiveSheet) {
        DispatchQueue.main.async {
            activeSheet = sheet
        }
    }

    var actionsCard: some View {
        VStack(spacing: 8) {
            Button {
                present(.refine)
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

            Button {
                present(.schedule)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                    Text("Schedule for later")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.niboInset)
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1))
                )
            }

            Button {
                present(.edit)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                    Text("Edit details")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.niboInset)
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1))
                )
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
                        .fill(Color.niboInset)
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

    // MARK: Ingredients

    var ingredientsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("🧂 Ingredients")
            VStack(spacing: 0) {
                ForEach(Array(live.items.enumerated()), id: \.element.id) { i, item in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.system(size: 14, weight: .medium))
                                .lineLimit(2)
                            if !item.weight.isEmpty {
                                Text(item.weight)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        Spacer(minLength: 0)
                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            Text("\(item.kcal)")
                                .font(.system(size: 14, weight: .semibold))
                                .monospacedDigit()
                            Text("kcal")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 10)
                    if i < live.items.count - 1 {
                        Divider()
                    }
                }
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
                        .fill(Color.niboWhite)
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
                                        Capsule().fill(Color.niboInset)
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

// MARK: - EditMealSheet

struct EditMealSheet: View {
    let base: LoggedMeal

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var type: String = "Lunch"
    @State private var kcal: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""

    private let mealTypes = ["Breakfast", "Lunch", "Snack", "Dinner"]

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        Int(kcal) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Meal name", text: $name)
                        .autocorrectionDisabled(false)
                }
                Section("Type") {
                    Picker("Type", selection: $type) {
                        ForEach(mealTypes, id: \.self) { t in
                            Text(LocalizedStringKey(t)).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Nutrition") {
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("kcal", text: $kcal)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                    }
                    HStack {
                        Text("Protein")
                        Spacer()
                        TextField("g", text: $protein)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("g").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Carbs")
                        Spacer()
                        TextField("g", text: $carbs)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("g").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Fat")
                        Spacer()
                        TextField("g", text: $fat)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("g").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Edit meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear {
                name    = base.name
                type    = base.type
                kcal    = "\(base.kcal)"
                protein = "\(base.protein)"
                carbs   = "\(base.carbs)"
                fat     = "\(base.fat)"
            }
        }
    }

    private func save() {
        appState.editMeal(
            id: base.id,
            name: name.trimmingCharacters(in: .whitespaces),
            type: type,
            kcal: Int(kcal) ?? base.kcal,
            protein: Int(protein) ?? base.protein,
            carbs: Int(carbs) ?? base.carbs,
            fat: Int(fat) ?? base.fat
        )
        dismiss()
    }
}

// MARK: - ScheduleMealSheet

struct ScheduleMealSheet: View {
    let base: LoggedMeal

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var selected: Set<DateOnly> = []

    /// Hashable wrapper for a calendar day (start-of-day) so we can
    /// store picked days in a Set.
    struct DateOnly: Hashable {
        let date: Date
        init(_ d: Date) {
            self.date = Calendar.current.startOfDay(for: d)
        }
    }

    private let cal = Calendar.current

    /// Two weeks of dates starting today.
    private var upcoming: [Date] {
        let start = cal.startOfDay(for: Date())
        return (0..<14).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    private var canSave: Bool { !selected.isEmpty }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header showing the meal being scheduled
                HStack(spacing: 12) {
                    Text(base.emoji).font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(base.name)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                        Text("\(base.kcal) kcal · \(base.type)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle(radius: 14)
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Text("Pick the days to plan this meal — tap again to deselect. We'll show it on those days for you to confirm.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .fixedSize(horizontal: false, vertical: true)

                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(upcoming, id: \.self) { day in
                            DayChip(
                                date: day,
                                isToday: cal.isDateInToday(day),
                                isSelected: selected.contains(DateOnly(day))
                            ) {
                                let key = DateOnly(day)
                                if selected.contains(key) {
                                    selected.remove(key)
                                } else {
                                    selected.insert(key)
                                }
                            }
                        }
                    }
                    .padding(20)
                }

                Button {
                    appState.scheduleMeal(from: base, onDates: selected.map(\.date))
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                        Text(selected.count <= 1
                             ? "Schedule"
                             : "Schedule on \(selected.count) days")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(canSave ? accentOrange : Color.secondary.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: canSave ? accentOrange.opacity(0.35) : .clear, radius: 10, y: 3)
                }
                .disabled(!canSave)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Schedule meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

private struct DayChip: View {
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let onTap: () -> Void

    private var weekday: String {
        let f = DateFormatter(); f.dateFormat = "EEE"
        return f.string(from: date)
    }
    private var day: String {
        let f = DateFormatter(); f.dateFormat = "d"
        return f.string(from: date)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(weekday)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .tracking(0.4)
                    .textCase(.uppercase)
                Text(day)
                    .font(.system(size: 18, weight: .bold))
                    .monospacedDigit()
                    .foregroundColor(isSelected ? .white : .primary)
                if isToday {
                    Text("today")
                        .font(.system(size: 9))
                        .foregroundColor(isSelected ? .white.opacity(0.85) : Color.secondary.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? accentOrange : Color.niboWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? accentOrange : Color.primary.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

