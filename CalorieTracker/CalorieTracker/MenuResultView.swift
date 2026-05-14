import SwiftUI

/// Shown after scanning a menu. A highlighted "best pick" given the
/// user's remaining budget + nutrition, then every dish ranked by
/// calories (most → least) with a nutrition score badge. Tap a dish
/// to log it.
struct MenuResultView: View {
    let analysis: MenuAnalysis
    let onClose: () -> Void
    let onLog: (MenuItem) -> Void

    /// All dishes, ranked most → least calories.
    private var ranked: [MenuItem] {
        analysis.items.sorted { $0.kcal > $1.kcal }
    }

    private var recommended: MenuItem? {
        guard let i = analysis.recommendationIndex,
              analysis.items.indices.contains(i) else { return nil }
        return analysis.items[i]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if let pick = recommended {
                        bestPickCard(pick)
                    }
                    allDishesCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color.niboCream)
            .navigationTitle("Menu picks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onClose() }
                        .font(NiboFont.inter(14, weight: .semibold))
                        .foregroundColor(.niboForest)
                }
            }
        }
    }

    // MARK: Best pick

    private func bestPickCard(_ pick: MenuItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                Text("BEST PICK FOR YOU")
                    .font(NiboFont.inter(11, weight: .semibold))
                    .tracking(0.6)
            }
            .foregroundColor(.niboForest)

            Text(pick.name)
                .font(NiboFont.inter(20, weight: .semibold))
                .tracking(-0.4)
                .foregroundColor(.niboForest)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 14) {
                metric("\(pick.kcal)", "kcal")
                Divider().frame(height: 28)
                metric("\(pick.quality)", "score")
                Divider().frame(height: 28)
                metric("\(pick.protein)g", "protein")
            }

            if !analysis.recommendationReason.isEmpty {
                Text(analysis.recommendationReason)
                    .font(NiboFont.inter(13))
                    .foregroundColor(.niboSage)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button { onLog(pick) } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Log this")
                        .font(NiboFont.inter(15, weight: .semibold))
                }
                .foregroundColor(.niboForest)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.niboMustard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.niboMustard.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.niboMustard, lineWidth: 1.5)
                )
        )
    }

    private func metric(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(NiboFont.inter(17, weight: .semibold))
                .foregroundColor(.niboForest)
                .monospacedDigit()
            Text(label)
                .font(NiboFont.inter(10, weight: .medium))
                .foregroundColor(.niboSoftGray)
                .tracking(0.4)
                .textCase(.uppercase)
        }
    }

    // MARK: All dishes

    private var allDishesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ALL DISHES")
                    .font(NiboFont.inter(11, weight: .semibold))
                    .foregroundColor(.niboSoftGray)
                    .tracking(0.6)
                Spacer()
                Text("most → fewest kcal")
                    .font(NiboFont.inter(10))
                    .foregroundColor(.niboSoftGray)
            }

            VStack(spacing: 0) {
                ForEach(Array(ranked.enumerated()), id: \.element.id) { i, item in
                    MenuDishRow(item: item,
                                isRecommended: item.id == recommended?.id,
                                onLog: { onLog(item) })
                    if i < ranked.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - MenuDishRow

struct MenuDishRow: View {
    let item: MenuItem
    let isRecommended: Bool
    let onLog: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Nutrition score badge
            ZStack {
                Circle()
                    .fill(qualityColor(item.quality).opacity(0.16))
                    .frame(width: 40, height: 40)
                Text("\(item.quality)")
                    .font(NiboFont.inter(14, weight: .semibold))
                    .foregroundColor(qualityColor(item.quality))
                    .monospacedDigit()
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(NiboFont.inter(14, weight: .medium))
                        .foregroundColor(.niboForest)
                        .lineLimit(2)
                    if isRecommended {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.niboMustard)
                    }
                }
                Text("\(item.kcal) kcal · \(item.protein)P / \(item.carbs)C / \(item.fat)F")
                    .font(NiboFont.inter(11))
                    .foregroundColor(.niboSoftGray)
                    .monospacedDigit()
                if !item.note.isEmpty {
                    Text(item.note)
                        .font(NiboFont.inter(11))
                        .foregroundColor(.niboSoftGray)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            Button(action: onLog) {
                Text("Log")
                    .font(NiboFont.inter(13, weight: .semibold))
                    .foregroundColor(.niboForest)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 14)
                    .background(Capsule().fill(Color.niboMustard))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 11)
    }
}
