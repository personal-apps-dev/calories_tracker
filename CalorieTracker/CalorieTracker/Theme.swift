import SwiftUI

// MARK: - Nibo brand tokens
//
// Source of truth lives at the top of the Nibo landing-page HTML.
// Keep these values in sync with the design-system reference there.

extension Color {
    /// Primary brand. Dark surfaces, body text on light bg.
    static let niboForest    = Color(hex: "1A2E22")
    /// Warm page background — the "plate".
    static let niboCream     = Color(hex: "FAF7F0")
    /// Accent — CTAs, highlights, "the bite".
    static let niboMustard   = Color(hex: "D4A437")
    /// Secondary text on cream surfaces.
    static let niboSage      = Color(hex: "4A5D52")
    /// Tertiary text, captions.
    static let niboSoftGray  = Color(hex: "7A8A80")
    /// Labels on forest (dark) surfaces.
    static let niboMist      = Color(hex: "A8B5AC")
    /// Card surface on cream backgrounds.
    static let niboWhite     = Color.white
    /// Subtle inset surface inside cards (e.g., chip backgrounds).
    static let niboInset     = Color(red: 26/255, green: 46/255, blue: 34/255, opacity: 0.04)
    /// Hairline rule on cream / white.
    static let niboHairline  = Color(red: 26/255, green: 46/255, blue: 34/255, opacity: 0.10)
}

/// Brand accent. Kept as the original symbol name so existing call
/// sites keep working — it now resolves to mustard, not orange.
let accentOrange: Color = .niboMustard

// MARK: - Typography
//
// Nibo uses Inter from Google Fonts. To enable it on iOS:
//   1. Drop Inter-Regular.ttf, Inter-Medium.ttf, Inter-SemiBold.ttf
//      into the project (Targets → Build Phases → Copy Bundle Resources)
//   2. Add them to the target's Info.plist via the build setting
//      INFOPLIST_KEY_UIAppFonts as an array of file names
//
// The helper below picks Inter when registered and falls back to
// the system font otherwise — so the app builds cleanly even before
// the .ttf files are added.

enum NiboFont {
    static func inter(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if UIFont.fontNames(forFamilyName: "Inter").isEmpty {
            return .system(size: size, weight: weight)
        }
        let name: String
        switch weight {
        case .semibold, .bold, .heavy, .black: name = "Inter-SemiBold"
        case .medium:                          name = "Inter-Medium"
        default:                               name = "Inter-Regular"
        }
        return .custom(name, size: size)
    }
}

// MARK: - Quality helpers

func qualityColor(_ q: Int) -> Color {
    if q >= 80 { return Color(hex: "3DB46D") }      // strong green — keeps semantic contrast
    if q >= 60 { return .niboMustard }              // brand peak = "good enough"
    if q >= 45 { return Color(hex: "C49A2E") }      // muted mustard
    return Color(hex: "B85C4A")                     // softened red — anti-shame
}

func qualityLabel(_ q: Int) -> String {
    if q >= 80 { return "Excellent" }
    if q >= 60 { return "Good" }
    if q >= 45 { return "Fair" }
    return "Could be better"
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

// MARK: - Card style

extension View {
    /// Card surface on the cream page background — white fill, hairline border.
    func cardStyle(radius: CGFloat = 16) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius)
                .fill(Color.niboWhite)
                .overlay(
                    RoundedRectangle(cornerRadius: radius)
                        .stroke(Color.niboHairline, lineWidth: 1)
                )
        )
    }

    /// Soft fade at the top and bottom of a scroll view so content
    /// melts into the background instead of butting against the edges.
    func scrollEdgeFade(top: CGFloat = 28, bottom: CGFloat = 96) -> some View {
        overlay(alignment: .top) {
            LinearGradient(
                colors: [Color.niboCream, Color.niboCream.opacity(0)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: top)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
        }
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [Color.niboCream.opacity(0), Color.niboCream],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: bottom)
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Logo mark
//
// Cream plate outline + mustard dot at upper-right.
// Stroke scales by size to match the SVG reference.

struct NiboLogoMark: View {
    var size: CGFloat = 28
    var stroke: Color = .niboForest
    var dot: Color = .niboMustard

    private var plate: CGFloat { size * 0.7 }
    private var dotSize: CGFloat { size * 0.20 }
    private var strokeWidth: CGFloat {
        switch size {
        case ..<24:  return max(2, size * 0.105)
        case ..<48:  return max(2, size * 0.080)
        default:     return max(2, size * 0.060)
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(stroke, lineWidth: strokeWidth)
                .frame(width: plate, height: plate)
            Circle()
                .fill(dot)
                .frame(width: dotSize, height: dotSize)
                .offset(x: size * 0.15, y: -size * 0.125)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Wordmark

struct NiboWordmark: View {
    var size: CGFloat = 22
    var color: Color = .niboForest

    var body: some View {
        Text("nibo")
            .font(NiboFont.inter(size, weight: .medium))
            .tracking(-0.5)
            .foregroundColor(color)
    }
}

struct NiboBrand: View {
    var size: CGFloat = 24
    var color: Color = .niboForest

    var body: some View {
        HStack(spacing: 8) {
            NiboLogoMark(size: size, stroke: color)
            NiboWordmark(size: size * 0.92, color: color)
        }
    }
}

// MARK: - Pill button styles
//
// Three pill variants matching the brand:
//   .niboPrimary   — forest fill, cream text       (CTA)
//   .niboSecondary — transparent, forest border     (secondary CTA)
//   .niboAccent    — mustard fill, forest text      (highlight)

struct NiboPillStyle: ButtonStyle {
    enum Variant { case primary, secondary, accent }
    let variant: Variant

    func makeBody(configuration: Configuration) -> some View {
        let bg: Color = {
            switch variant {
            case .primary:   return .niboForest
            case .secondary: return .clear
            case .accent:    return .niboMustard
            }
        }()
        let fg: Color = {
            switch variant {
            case .primary:   return .niboCream
            case .secondary: return .niboForest
            case .accent:    return .niboForest
            }
        }()
        let strokeColor: Color = {
            switch variant {
            case .primary:   return .niboForest
            case .secondary: return .niboForest
            case .accent:    return .niboMustard
            }
        }()
        return configuration.label
            .font(NiboFont.inter(13, weight: .medium))
            .padding(.vertical, 12)
            .padding(.horizontal, 22)
            .background(
                Capsule().fill(bg)
                    .overlay(Capsule().stroke(strokeColor, lineWidth: 1))
            )
            .foregroundColor(fg)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
