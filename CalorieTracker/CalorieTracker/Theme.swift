import SwiftUI

let accentOrange = Color(hex: "FF6B35")

// MARK: - Quality helpers

func qualityColor(_ q: Int) -> Color {
    if q >= 80 { return Color(hex: "3DB46D") }
    if q >= 60 { return Color(hex: "F4B740") }
    if q >= 45 { return Color(hex: "E8954E") }
    return Color(hex: "E86A6A")
}

func qualityLabel(_ q: Int) -> String {
    if q >= 80 { return "Excellent" }
    if q >= 60 { return "Good" }
    if q >= 45 { return "Fair" }
    return "Needs work"
}

// MARK: - Color helpers

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var n: UInt64 = 0
        Scanner(string: h).scanHexInt64(&n)
        self.init(
            red:   Double((n >> 16) & 0xFF) / 255,
            green: Double((n >> 8)  & 0xFF) / 255,
            blue:  Double( n        & 0xFF) / 255
        )
    }
}

// MARK: - Card style modifier

extension View {
    func cardStyle(radius: CGFloat = 22) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: radius)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
    }
}
