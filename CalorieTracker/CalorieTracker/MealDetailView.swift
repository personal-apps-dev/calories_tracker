import SwiftUI

struct MealDetailView: View {
    let meal: LoggedMeal
    @Environment(\.dismiss) var dismiss

    private var factors: [QualityFactor] {
        qualityFactors(kcal: meal.kcal, protein: meal.protein, carbs: meal.carbs, fat: meal.fat)
    }

    private var timeLabel: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: meal.timestamp)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    headerCard
                    macrosCard
                    scoreCard
                    factorsCard
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
        }
    }

    // MARK: Header

    var headerCard: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: gradientFor(type: meal.type),
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 64, height: 64)
                .overlay(Text(meal.emoji).font(.system(size: 32)))

            VStack(alignment: .leading, spacing: 3) {
                Text(meal.type.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(.secondary)
                Text(meal.name)
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
                Text("\(meal.kcal)")
                    .font(.system(size: 36, weight: .bold))
                    .tracking(-1)
                    .monospacedDigit()
                Text("kcal total")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                MacroLineView(label: "Protein", grams: meal.protein, totalKcal: meal.kcal, gPerKcal: 4, color: Color(hex: "5B8DEF"))
                MacroLineView(label: "Carbs",   grams: meal.carbs,   totalKcal: meal.kcal, gPerKcal: 4, color: Color(hex: "F4B740"))
                MacroLineView(label: "Fat",     grams: meal.fat,     totalKcal: meal.kcal, gPerKcal: 9, color: Color(hex: "E86A6A"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: Score hero

    var scoreCard: some View {
        let qc = qualityColor(meal.quality)
        return HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.06), lineWidth: 9)
                    .frame(width: 92, height: 92)
                Circle()
                    .trim(from: 0, to: Double(meal.quality) / 100)
                    .stroke(qc, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .frame(width: 92, height: 92)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(meal.quality)")
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
                Text(qualityLabel(meal.quality))
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
        switch meal.quality {
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
