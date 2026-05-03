import Foundation
import UIKit

// MARK: - Codable response shapes

private struct ClaudeResponse: Codable {
    let content: [ClaudeContent]
}

private struct ClaudeContent: Codable {
    let type: String
    let text: String?
}

private struct NutritionJSON: Codable {
    let name: String
    let confidence: Int
    let kcal: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let items: [ItemJSON]

    private enum CodingKeys: String, CodingKey {
        case name, confidence, kcal, protein, carbs, fat, items
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name       = try c.decode(String.self, forKey: .name)
        confidence = try Self.flexibleInt(c, .confidence)
        kcal       = try Self.flexibleInt(c, .kcal)
        protein    = try Self.flexibleInt(c, .protein)
        carbs      = try Self.flexibleInt(c, .carbs)
        fat        = try Self.flexibleInt(c, .fat)
        items      = (try? c.decode([ItemJSON].self, forKey: .items)) ?? []
    }

    /// Accepts Int, Double, or numeric String — Claude occasionally
    /// returns "25" or 25.0 instead of 25, especially with non-English
    /// language instructions.
    private static func flexibleInt(_ c: KeyedDecodingContainer<CodingKeys>,
                                    _ key: CodingKeys) throws -> Int {
        if let i = try? c.decode(Int.self, forKey: key) { return i }
        if let d = try? c.decode(Double.self, forKey: key) { return Int(d.rounded()) }
        if let s = try? c.decode(String.self, forKey: key),
           let d = Double(s.replacingOccurrences(of: ",", with: ".")) {
            return Int(d.rounded())
        }
        return 0
    }
}

private struct ItemJSON: Codable {
    let name: String
    let kcal: Int
    let weight: String

    private enum CodingKeys: String, CodingKey { case name, kcal, weight }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        if let i = try? c.decode(Int.self, forKey: .kcal) { kcal = i }
        else if let d = try? c.decode(Double.self, forKey: .kcal) { kcal = Int(d.rounded()) }
        else { kcal = 0 }
        weight = (try? c.decode(String.self, forKey: .weight)) ?? ""
    }
}

// MARK: - ClaudeService

class ClaudeService {
    static let shared = ClaudeService()
    private init() {}

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    func analyzeFood(image: UIImage, apiKey: String, language: AppLanguage = .system) async throws -> FoodAnalysis {
        let resized = Self.resize(image, maxDim: 1024)
        guard let imageData = resized.jpegData(compressionQuality: 0.75) else {
            throw AnalysisError.imageConversion
        }
        let base64 = imageData.base64EncodedString()

        let prompt = """
        Analyze this food photo. Return ONLY a JSON object — no markdown, no explanation, nothing else.

        Required format:
        {
          "name": "Dish name (concise)",
          "confidence": 88,
          "kcal": 450,
          "protein": 25,
          "carbs": 45,
          "fat": 18,
          "items": [
            { "name": "Ingredient 1", "kcal": 200, "weight": "100g" },
            { "name": "Ingredient 2", "kcal": 150, "weight": "80g" }
          ]
        }

        Rules:
        - Estimate realistic nutrition values for the portion shown
        - Include 2-5 main ingredients
        - confidence is 0-100 (how certain you are)
        - All weights as strings like "100g", "2 tbsp", "1 large"
        \(Self.languageInstruction(language))
        """

        let userContent: [[String: Any]] = [
            [
                "type": "image",
                "source": [
                    "type": "base64",
                    "media_type": "image/jpeg",
                    "data": base64
                ]
            ],
            ["type": "text", "text": prompt]
        ]

        return try await runMessages(content: userContent, apiKey: apiKey)
    }

    func analyzeFoodText(description: String, apiKey: String, language: AppLanguage = .system) async throws -> FoodAnalysis {
        let prompt = """
        A user described what they ate or drank. Estimate the nutrition.

        User description:
        \"\"\"
        \(description)
        \"\"\"

        Even if the input is just a single ingredient, a beverage, a snack,
        or a partial meal, ALWAYS return a nutrition estimate — never refuse,
        never leave fields empty.

        Return ONLY a JSON object — no markdown, no preamble, no explanation.
        The very first character of your reply must be "{" and the last "}".

        Required format:
        {
          "name": "Concise dish or drink name",
          "confidence": 70,
          "kcal": 25,
          "protein": 1,
          "carbs": 2,
          "fat": 1,
          "items": [
            { "name": "Ingredient or component", "kcal": 5, "weight": "30 ml" }
          ]
        }

        Rules:
        - ALWAYS return JSON. Even for a single ingredient or a drink, return one item with reasonable nutrition.
        - Respect any quantity the user gave ("10 grams" means 10g, not 100g; "small cup" means small)
        - If no quantity is given, assume a typical serving (e.g. one cup of coffee, one apple)
        - 1-5 entries in items
        - confidence 0-100 — only set 0 if the input is genuinely not edible at all
        - Weights as strings like "10g", "200 ml", "1 large", "1 cup"
        \(Self.languageInstruction(language))
        """

        let userContent: [[String: Any]] = [
            ["type": "text", "text": prompt]
        ]

        return try await runMessages(content: userContent, apiKey: apiKey)
    }

    func refineFood(base: LoggedMeal,
                    additions: String,
                    apiKey: String,
                    language: AppLanguage = .system) async throws -> FoodAnalysis {
        let prompt = """
        A user already logged this meal:
        Name: \(base.name)
        Totals: \(base.kcal) kcal — \(base.protein)g protein, \(base.carbs)g carbs, \(base.fat)g fat

        They want to update it with these additions / changes:
        \"\"\"
        \(additions)
        \"\"\"

        ALWAYS return a JSON estimate — never refuse, never leave fields empty.
        Return ONLY a JSON object — no markdown, no preamble, no explanation.
        The very first character of your reply must be "{" and the last "}".

        Required format:
        {
          "name": "Updated dish name (concise, reflecting the addition)",
          "confidence": 70,
          "kcal": 600,
          "protein": 30,
          "carbs": 50,
          "fat": 22,
          "items": [
            { "name": "Original component", "kcal": 400, "weight": "..." },
            { "name": "Added component",    "kcal": 200, "weight": "..." }
          ]
        }

        Rules:
        - Sum quantities sensibly. If the addition adds ~200 kcal, the new total is roughly base + 200.
        - Combine, do not replace, unless the user explicitly says "replace" / "instead of" / "swap"
        - 1-5 ingredients in items, including the new ones
        - confidence 0-100
        - Weights as strings like "100g", "1 cup", "2 slices"
        \(Self.languageInstruction(language))
        """

        let userContent: [[String: Any]] = [["type": "text", "text": prompt]]
        return try await runMessages(content: userContent, apiKey: apiKey)
    }

    private func runMessages(content: [[String: Any]], apiKey: String) async throws -> FoodAnalysis {
        let requestBody: [String: Any] = [
            "model": "claude-opus-4-7",
            "max_tokens": 1200,
            "messages": [[
                "role": "user",
                "content": content
            ]]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AnalysisError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw AnalysisError.httpError(httpResponse.statusCode, body)
        }

        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        guard let text = claudeResponse.content.first(where: { $0.type == "text" })?.text else {
            throw AnalysisError.noText
        }

        let jsonText = extractJSON(from: text)
        guard let jsonData = jsonText.data(using: .utf8) else {
            throw AnalysisError.parseError
        }

        let nutrition = try JSONDecoder().decode(NutritionJSON.self, from: jsonData)

        return FoodAnalysis(
            name: nutrition.name,
            confidence: min(100, max(0, nutrition.confidence)),
            kcal: max(0, nutrition.kcal),
            protein: max(0, nutrition.protein),
            carbs: max(0, nutrition.carbs),
            fat: max(0, nutrition.fat),
            items: nutrition.items.map {
                AnalysisIngredient(name: $0.name, kcal: $0.kcal, weight: $0.weight)
            }
        )
    }

    private static func languageInstruction(_ lang: AppLanguage) -> String {
        guard let prompt = lang.claudePromptName else { return "" }
        return """

        Important: write all text fields in the JSON ("name", item "name"s, and item "weight"s like "100 г") in \(prompt). Keep the JSON keys themselves in English.
        """
    }

    private static func resize(_ image: UIImage, maxDim: CGFloat) -> UIImage {
        let w = image.size.width, h = image.size.height
        let scale = min(1, maxDim / max(w, h))
        if scale >= 1 { return image }
        let newSize = CGSize(width: w * scale, height: h * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func extractJSON(from text: String) -> String {
        if let start = text.range(of: "{"),
           let end = text.range(of: "}", options: .backwards) {
            return String(text[start.lowerBound..<end.upperBound])
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum AnalysisError: LocalizedError {
    case imageConversion
    case invalidResponse
    case httpError(Int, String)
    case noText
    case parseError

    var errorDescription: String? {
        switch self {
        case .imageConversion:        return "Failed to process image"
        case .invalidResponse:        return "Invalid server response"
        case .httpError(let c, let b): return "API error \(c): \(b)"
        case .noText:                 return "No analysis text in response"
        case .parseError:             return "Failed to parse nutrition data"
        }
    }
}
