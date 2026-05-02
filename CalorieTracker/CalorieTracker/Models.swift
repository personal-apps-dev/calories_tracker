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

// Historical data kept as a sample placeholder until backend/sync is built.
let sampleHistoryDays: [DayRecord] = [
    DayRecord(label: "Yesterday", date: "Apr 29", consumed: 2080, storedGoal: 2200, mealCount: 4, meals: [
        Meal(id: 5,  type: "Breakfast", emoji: "🥞", name: "Pancakes & maple syrup",
             kcal: 480, time: "8:30 AM",  quality: 62, gradient: [Color(hex: "FFE0B2"), Color(hex: "FFB74D")]),
        Meal(id: 6,  type: "Lunch",     emoji: "🍔", name: "Cheeseburger & fries",
             kcal: 820, time: "1:15 PM",  quality: 38, gradient: [Color(hex: "FFCCBC"), Color(hex: "FF8A65")]),
        Meal(id: 7,  type: "Snack",     emoji: "🍿", name: "Popcorn",
             kcal: 180, time: "4:00 PM",  quality: 52, gradient: [Color(hex: "F4E4C1"), Color(hex: "E8B4B8")]),
        Meal(id: 8,  type: "Dinner",    emoji: "🍣", name: "Salmon & rice bowl",
             kcal: 600, time: "7:30 PM",  quality: 84, gradient: [Color(hex: "C8E6C9"), Color(hex: "81C784")]),
    ]),
    DayRecord(label: "Mon",  date: "Apr 28", consumed: 2310, storedGoal: 2200, mealCount: 5, meals: [
        Meal(id: 9,  type: "Breakfast", emoji: "🥐", name: "Croissant & latte",
             kcal: 420, time: "8:00 AM",  quality: 55, gradient: [Color(hex: "FFE0B2"), Color(hex: "FFB74D")]),
        Meal(id: 10, type: "Lunch",     emoji: "🌯", name: "Burrito bowl",
             kcal: 760, time: "12:30 PM", quality: 70, gradient: [Color(hex: "C8E6C9"), Color(hex: "81C784")]),
        Meal(id: 11, type: "Snack",     emoji: "🍫", name: "Dark chocolate",
             kcal: 200, time: "3:30 PM",  quality: 65, gradient: [Color(hex: "FFCCBC"), Color(hex: "FF8A65")]),
        Meal(id: 12, type: "Dinner",    emoji: "🍕", name: "Margherita pizza (2 slices)",
             kcal: 720, time: "7:45 PM",  quality: 48, gradient: [Color(hex: "FFE0B2"), Color(hex: "FFB74D")]),
        Meal(id: 13, type: "Snack",     emoji: "🍷", name: "Glass of red wine",
             kcal: 210, time: "9:00 PM",  quality: 40, gradient: [Color(hex: "E8B4B8"), Color(hex: "C48B9F")]),
    ]),
    DayRecord(label: "Sun",  date: "Apr 27", consumed: 1890, storedGoal: 2200, mealCount: 3, meals: [
        Meal(id: 14, type: "Brunch",  emoji: "🥑", name: "Avocado toast",
             kcal: 540, time: "10:30 AM", quality: 88, gradient: [Color(hex: "C8E6C9"), Color(hex: "81C784")]),
        Meal(id: 15, type: "Lunch",   emoji: "🍝", name: "Pasta carbonara",
             kcal: 720, time: "2:00 PM",  quality: 62, gradient: [Color(hex: "FFE0B2"), Color(hex: "FFB74D")]),
        Meal(id: 16, type: "Dinner",  emoji: "🥗", name: "Caesar salad & soup",
             kcal: 630, time: "7:00 PM",  quality: 82, gradient: [Color(hex: "C8E6C9"), Color(hex: "81C784")]),
    ]),
    DayRecord(label: "Sat",  date: "Apr 26", consumed: 2150, storedGoal: 2200, mealCount: 4, meals: []),
    DayRecord(label: "Fri",  date: "Apr 25", consumed: 1950, storedGoal: 2200, mealCount: 4, meals: []),
]

let weekTrends: [TrendEntry] = [
    TrendEntry(label: "Thu", consumed: 1980, quality: 72),
    TrendEntry(label: "Fri", consumed: 1950, quality: 78),
    TrendEntry(label: "Sat", consumed: 2150, quality: 65),
    TrendEntry(label: "Sun", consumed: 1890, quality: 82),
    TrendEntry(label: "Mon", consumed: 2310, quality: 54),
    TrendEntry(label: "Tue", consumed: 2080, quality: 68),
    TrendEntry(label: "Wed", consumed: 1420, quality: 81),
]

let monthTrends: [TrendEntry] = (1...30).map { i in
    let v = Double(i)
    return TrendEntry(
        label: "\(i)",
        consumed: max(1200, Int(1700 + sin(v * 0.6) * 350 + cos(v * 1.3) * 150)),
        quality:  max(40, min(95, Int(70 + sin(v * 0.4) * 12 + cos(v * 1.7) * 6)))
    )
}

let yearTrends: [TrendEntry] = zip(
    ["May","Jun","Jul","Aug","Sep","Oct","Nov","Dec","Jan","Feb","Mar","Apr"],
    Array(0...11)
).map { label, i in
    let v = Double(i)
    return TrendEntry(
        label: label,
        consumed: Int(1900 + sin(v * 0.7) * 200 + cos(v * 1.2) * 80),
        quality:  Int(68  + sin(v * 0.5) * 10  + cos(v * 1.1) * 4)
    )
}
