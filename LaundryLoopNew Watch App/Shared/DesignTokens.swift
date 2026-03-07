import SwiftUI

/// Centralized typography, color, and spacing tokens for the Laundry Loop surfaces.
enum DesignTokens {
    static let cardCornerRadius: CGFloat = 18
    static let sectionSpacing: CGFloat = 16
    static let heroPadding: CGFloat = 20
    static let bannerHeight: CGFloat = 48
    static let controlSpacing: CGFloat = 12
    static let infoSpacing: CGFloat = 8

    static func tint(for kind: CycleKind) -> Color {
        kind == .washer ? Color.accentColor : Color.orange
    }

    static func gradient(for kind: CycleKind) -> LinearGradient {
        let colors: [Color] = kind == .washer
            ? [Color.blue.opacity(0.8), Color.blue.opacity(0.45)]
            : [Color.orange.opacity(0.8), Color.orange.opacity(0.45)]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var bannerMaterial: Color { .white.opacity(0.12) }
    static let pageBackground: Color = .black
    static var cardMaterial: Color { .white.opacity(0.08) }
    static var badgeMaterial: Color { .white.opacity(0.14) }
}
