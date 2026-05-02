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

    /// Soft fade at the top and bottom of a scroll view so content
    /// melts into the background instead of butting against the edges.
    func scrollEdgeFade(top: CGFloat = 28, bottom: CGFloat = 96) -> some View {
        overlay(alignment: .top) {
            LinearGradient(
                colors: [
                    Color(UIColor.systemBackground),
                    Color(UIColor.systemBackground).opacity(0)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: top)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
        }
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [
                    Color(UIColor.systemBackground).opacity(0),
                    Color(UIColor.systemBackground)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: bottom)
            .allowsHitTesting(false)
        }
    }
}
