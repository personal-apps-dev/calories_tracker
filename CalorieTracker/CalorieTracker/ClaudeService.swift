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
}

private struct ItemJSON: Codable {
    let name: String
    let kcal: Int
    let weight: String
}

// MARK: - ClaudeService

class ClaudeService {
    static let shared = ClaudeService()
    private init() {}

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    func analyzeFood(image: UIImage, apiKey: String) async throws -> FoodAnalysis {
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
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
        """

        let requestBody: [String: Any] = [
            "model": "claude-opus-4-7",
            "max_tokens": 600,
            "messages": [[
                "role": "user",
                "content": [
                    [
                        "type": "image",
                        "source": [
                            "type": "base64",
                            "media_type": "image/jpeg",
                            "data": base64
                        ]
                    ],
                    [
                        "type": "text",
                        "text": prompt
                    ]
                ]
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
            throw AnalysisError.httpError(httpResponse.statusCode)
        }

        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        guard let text = claudeResponse.content.first(where: { $0.type == "text" })?.text else {
            throw AnalysisError.noText
        }

        // Extract JSON from the response (strip any accidental markdown)
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

    private func extractJSON(from text: String) -> String {
        // Handle responses that might be wrapped in markdown code blocks
        if let start = text.range(of: "{"),
           let end = text.range(of: "}", options: .backwards) {
            return String(text[start.lowerBound...end.upperBound])
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum AnalysisError: LocalizedError {
    case imageConversion
    case invalidResponse
    case httpError(Int)
    case noText
    case parseError

    var errorDescription: String? {
        switch self {
        case .imageConversion:  return "Failed to process image"
        case .invalidResponse:  return "Invalid server response"
        case .httpError(let c): return "Server error \(c)"
        case .noText:           return "No analysis text in response"
        case .parseError:       return "Failed to parse nutrition data"
        }
    }
}
