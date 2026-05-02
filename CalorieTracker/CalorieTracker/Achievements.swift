import SwiftUI

// MARK: - Streak emoji tier

func streakEmoji(_ days: Int) -> String {
    switch days {
    case 0:          return "✨"
    case 1..<10:     return "🔥"
    case 10..<30:    return "🔥🔥"
    case 30..<60:    return "🔥🔥🔥"
    case 60..<100:   return "🔥🔥🔥🔥"
    case 100..<365:  return "💎"
    default:         return "👑"
    }
}

// MARK: - Achievement model

struct Achievement: Identifiable {
    let id: String
    let icon: String
    let title: String
    let description: String
    let target: Int
    let progress: Int

    var isUnlocked: Bool { progress >= target }
    var fraction: Double {
        guard target > 0 else { return 0 }
        return min(1, Double(progress) / Double(target))
    }
}

@MainActor
func buildAchievements(_ s: AppState) -> [Achievement] {
    [
        Achievement(id: "first_log", icon: "🌱",
                    title: "First Bite",
                    description: "Log your very first meal",
                    target: 1, progress: min(1, s.totalMealsLogged)),
        Achievement(id: "streak_7", icon: "🔥",
                    title: "Week Warrior",
                    description: "Reach a 7-day streak",
                    target: 7, progress: min(7, s.streak)),
        Achievement(id: "streak_30", icon: "🚀",
                    title: "Monthly Master",
                    description: "Reach a 30-day streak",
                    target: 30, progress: min(30, s.streak)),
        Achievement(id: "streak_100", icon: "💎",
                    title: "Century Club",
                    description: "Hit a 100-day streak",
                    target: 100, progress: min(100, s.streak)),
        Achievement(id: "meals_50", icon: "🍽️",
                    title: "Half Century",
                    description: "Log 50 meals total",
                    target: 50, progress: min(50, s.totalMealsLogged)),
        Achievement(id: "meals_500", icon: "🏅",
                    title: "Logging Legend",
                    description: "Log 500 meals total",
                    target: 500, progress: min(500, s.totalMealsLogged)),
        Achievement(id: "on_goal_7", icon: "🎯",
                    title: "Goal Crusher",
                    description: "Hit your calorie goal 7 times",
                    target: 7, progress: min(7, s.daysOnGoal)),
        Achievement(id: "quality_excellent", icon: "🥗",
                    title: "Clean Eater",
                    description: "Log a day with 80+ avg food quality",
                    target: 1, progress: min(1, s.perfectQualityDays)),
        Achievement(id: "active_day", icon: "💪",
                    title: "Burn Baby Burn",
                    description: "Burn 500+ kcal in a day",
                    target: 1, progress: min(1, s.activeDays)),
        Achievement(id: "health_connected", icon: "❤️",
                    title: "Synced Up",
                    description: "Connect to Apple Health",
                    target: 1, progress: s.healthKitAuthorized ? 1 : 0),
    ]
}

// MARK: - AchievementsView

struct AchievementsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    private var achievements: [Achievement] { buildAchievements(appState) }
    private var unlockedCount: Int { achievements.filter(\.isUnlocked).count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    headerCard
                    ForEach(achievements) { ach in
                        AchievementRow(achievement: ach)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 32)
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("Achievements")
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

    var headerCard: some View {
        VStack(spacing: 6) {
            Text(streakEmoji(appState.streak))
                .font(.system(size: 56))
                .padding(.bottom, 2)

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(appState.streak)")
                    .font(.system(size: 40, weight: .bold))
                    .tracking(-1.2)
                    .monospacedDigit()
                Text(appState.streak == 1 ? "day streak" : "day streak")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Text("Best: \(appState.longestStreak) days")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)

            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 11))
                    .foregroundColor(accentOrange)
                Text("\(unlockedCount) of \(achievements.count) unlocked")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(accentOrange)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Capsule().fill(accentOrange.opacity(0.12)))
            .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

struct AchievementRow: View {
    let achievement: Achievement

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(achievement.isUnlocked
                          ? accentOrange.opacity(0.15)
                          : Color(UIColor.tertiarySystemBackground))
                    .frame(width: 52, height: 52)
                Text(achievement.icon)
                    .font(.system(size: 26))
                    .saturation(achievement.isUnlocked ? 1 : 0)
                    .opacity(achievement.isUnlocked ? 1 : 0.45)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(achievement.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
                    if achievement.isUnlocked {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(accentOrange)
                    }
                    Spacer()
                }
                Text(achievement.description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if achievement.target > 1 {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.primary.opacity(0.06))
                                .frame(height: 4)
                            Capsule()
                                .fill(achievement.isUnlocked
                                      ? Color(hex: "3DB46D")
                                      : accentOrange)
                                .frame(width: geo.size.width * achievement.fraction, height: 4)
                        }
                    }
                    .frame(height: 4)
                    .padding(.top, 6)

                    HStack {
                        Spacer()
                        Text("\(achievement.progress) / \(achievement.target)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(radius: 18)
    }
}
