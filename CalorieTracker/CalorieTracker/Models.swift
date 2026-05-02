import SwiftUI

// MARK: - Data Models

struct Meal: Identifiable {
    let id: Int
    let type: String
    let emoji: String
    let name: String
    let kcal: Int
    let time: String
    let quality: Int
    let gradient: [Color]
}

struct Activity: Identifiable {
    let id: Int
    let type: String
    let emoji: String
    let kcal: Int
    let duration: String
}

struct MacroStat {
    let grams: Int
    let goal: Int
}

struct DayRecord: Identifiable {
    let id = UUID()
    let label: String
    let date: String
    let consumed: Int
    let storedGoal: Int?
    let mealCount: Int
    let meals: [Meal]
}

struct AnalysisIngredient: Identifiable {
    let id = UUID()
    let name: String
    let kcal: Int
    let weight: String
}

struct FoodAnalysis {
    let name: String
    let confidence: Int
    let kcal: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let items: [AnalysisIngredient]
}

struct TrendEntry {
    let label: String
    let consumed: Int
    let quality: Int
}

// MARK: - LoggedMeal (persisted)

struct LoggedMeal: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let type: String
    let emoji: String
    let name: String
    let kcal: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let quality: Int

    init(id: UUID = UUID(), timestamp: Date = Date(),
         type: String, emoji: String, name: String,
         kcal: Int, protein: Int, carbs: Int, fat: Int, quality: Int) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.emoji = emoji
        self.name = name
        self.kcal = kcal
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.quality = quality
    }

    var asMeal: Meal {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return Meal(
            id: id.hashValue,
            type: type,
            emoji: emoji,
            name: name,
            kcal: kcal,
            time: f.string(from: timestamp),
            quality: quality,
            gradient: gradientFor(type: type)
        )
    }

    private static let storeKey = "loggedMeals.v1"

    static func loadAll() -> [LoggedMeal] {
        guard let data = UserDefaults.standard.data(forKey: storeKey),
              let arr = try? JSONDecoder().decode([LoggedMeal].self, from: data) else {
            return []
        }
        return arr
    }

    static func saveAll(_ meals: [LoggedMeal]) {
        if let data = try? JSONEncoder().encode(meals) {
            UserDefaults.standard.set(data, forKey: storeKey)
        }
    }
}

func gradientFor(type: String) -> [Color] {
    switch type.lowercased() {
    case "breakfast", "brunch":
        return [Color(hex: "F4E4C1"), Color(hex: "E8B4B8")]
    case "lunch":
        return [Color(hex: "C8E6C9"), Color(hex: "81C784")]
    case "snack":
        return [Color(hex: "FFCCBC"), Color(hex: "FF8A65")]
    case "dinner":
        return [Color(hex: "FFE0B2"), Color(hex: "FFB74D")]
    default:
        return [Color(hex: "F4E4C1"), Color(hex: "E8B4B8")]
    }
}

func mealTypeForNow(_ date: Date = Date()) -> String {
    let h = Calendar.current.component(.hour, from: date)
    switch h {
    case 5..<11:  return "Breakfast"
    case 11..<15: return "Lunch"
    case 15..<17: return "Snack"
    case 17..<22: return "Dinner"
    default:      return "Snack"
    }
}

func mealEmojiFor(name: String, type: String) -> String {
    let n = name.lowercased()
    if n.contains("salad") { return "🥗" }
    if n.contains("burger") { return "🍔" }
    if n.contains("pizza") { return "🍕" }
    if n.contains("pasta") || n.contains("spaghetti") { return "🍝" }
    if n.contains("rice") || n.contains("bowl") { return "🍚" }
    if n.contains("sushi") || n.contains("salmon") { return "🍣" }
    if n.contains("egg") { return "🍳" }
    if n.contains("bread") || n.contains("toast") || n.contains("sandwich") { return "🥪" }
    if n.contains("apple") || n.contains("fruit") { return "🍎" }
    if n.contains("yogurt") || n.contains("oat") || n.contains("cereal") { return "🥣" }
    if n.contains("chicken") { return "🍗" }
    if n.contains("steak") || n.contains("beef") { return "🥩" }
    if n.contains("avocado") { return "🥑" }
    switch type.lowercased() {
    case "breakfast": return "🥣"
    case "lunch":     return "🥗"
    case "snack":     return "🍎"
    case "dinner":    return "🍽️"
    default:          return "🍽️"
    }
}

// Quality heuristic for new logs from a Claude analysis. Penalizes high
// fat / low protein density; rewards reasonable kcal-to-protein ratios.
func estimateQuality(kcal: Int, protein: Int, carbs: Int, fat: Int) -> Int {
    guard kcal > 0 else { return 60 }
    let proteinPct = Double(protein * 4) / Double(kcal)
    let fatPct     = Double(fat * 9)     / Double(kcal)
    var score = 70.0
    score += (proteinPct - 0.20) * 80   // higher protein density helps
    score -= max(0, fatPct - 0.35) * 90  // penalize >35% fat
    if kcal > 800 { score -= 8 }
    if kcal < 200 { score += 4 }
    return max(20, min(98, Int(score.rounded())))
}

// MARK: - Score explanation

enum FactorImpact { case positive, neutral, negative }

struct QualityFactor: Identifiable {
    let id = UUID()
    let category: String   // e.g. "Protein"
    let title: String      // e.g. "Strong protein"
    let detail: String     // e.g. "26% of calories"
    let impact: FactorImpact
}

func qualityFactors(kcal: Int, protein: Int, carbs: Int, fat: Int) -> [QualityFactor] {
    guard kcal > 0 else { return [] }

    let proteinPct = Int((Double(protein * 4) / Double(kcal) * 100).rounded())
    let carbsPct   = Int((Double(carbs   * 4) / Double(kcal) * 100).rounded())
    let fatPct     = Int((Double(fat     * 9) / Double(kcal) * 100).rounded())

    var out: [QualityFactor] = []

    // Protein density
    if proteinPct >= 25 {
        out.append(.init(category: "Protein",
                         title: "Excellent protein density",
                         detail: "\(proteinPct)% of calories — keeps you full and supports muscle.",
                         impact: .positive))
    } else if proteinPct >= 15 {
        out.append(.init(category: "Protein",
                         title: "Decent protein",
                         detail: "\(proteinPct)% of calories from protein.",
                         impact: .neutral))
    } else {
        out.append(.init(category: "Protein",
                         title: "Low protein",
                         detail: "Only \(proteinPct)% of calories from protein — try to add a lean source.",
                         impact: .negative))
    }

    // Fat density
    if fatPct > 45 {
        out.append(.init(category: "Fat",
                         title: "Very fat-heavy",
                         detail: "\(fatPct)% of calories from fat — consider trimming oils or fatty cuts.",
                         impact: .negative))
    } else if fatPct > 35 {
        out.append(.init(category: "Fat",
                         title: "High fat",
                         detail: "\(fatPct)% of calories from fat.",
                         impact: .negative))
    } else if fatPct >= 20 {
        out.append(.init(category: "Fat",
                         title: "Balanced fat",
                         detail: "\(fatPct)% of calories from fat — within a healthy range.",
                         impact: .neutral))
    } else {
        out.append(.init(category: "Fat",
                         title: "Lean profile",
                         detail: "Only \(fatPct)% of calories from fat.",
                         impact: .positive))
    }

    // Carbs (informational mostly)
    out.append(.init(category: "Carbs",
                     title: "Carbs share",
                     detail: "\(carbsPct)% of calories from carbs.",
                     impact: .neutral))

    // Portion size
    if kcal > 900 {
        out.append(.init(category: "Portion",
                         title: "Large portion",
                         detail: "\(kcal) kcal in one sitting — fine occasionally, watch the daily total.",
                         impact: .negative))
    } else if kcal > 600 {
        out.append(.init(category: "Portion",
                         title: "Substantial meal",
                         detail: "\(kcal) kcal — typical main-course size.",
                         impact: .neutral))
    } else if kcal < 200 {
        out.append(.init(category: "Portion",
                         title: "Light snack",
                         detail: "Only \(kcal) kcal — easy to keep on track.",
                         impact: .positive))
    } else {
        out.append(.init(category: "Portion",
                         title: "Reasonable size",
                         detail: "\(kcal) kcal — moderate portion.",
                         impact: .neutral))
    }

    return out
}

// MARK: - Sample data for Diary / Trends prototypes

let fallbackAnalysis = FoodAnalysis(
    name: "Avocado toast w/ poached egg",
    confidence: 94, kcal: 385,
    protein: 16, carbs: 32, fat: 22,
    items: [
        AnalysisIngredient(name: "Sourdough bread",       kcal: 120, weight: "60g"),
        AnalysisIngredient(name: "Avocado",               kcal: 160, weight: "½ medium"),
        AnalysisIngredient(name: "Poached egg",           kcal: 78,  weight: "1 large"),
        AnalysisIngredient(name: "Olive oil & seasoning", kcal: 27,  weight: "~5ml"),
    ]
)

// Historical / trend data is computed live from `AppState.loggedMeals`
// — see AppState.recentDays / weekTrendEntries / monthTrendEntries /
// yearTrendEntries.
