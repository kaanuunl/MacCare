import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "system"
    case dark = "dark"
    case light = "light"

    var id: String { rawValue }

    var displayNameKey: L10nKey {
        switch self {
        case .system: return .themeSystem
        case .dark: return .themeDark
        case .light: return .themeLight
        }
    }

    var iconName: String {
        switch self {
        case .system: return "circle.righthalf.filled"
        case .dark: return "moon.stars.fill"
        case .light: return "sun.max.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
}

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("app_theme") var currentTheme: String = "system" {
        didSet {
            objectWillChange.send()
        }
    }

    var theme: AppTheme {
        get { AppTheme(rawValue: currentTheme) ?? .system }
        set { currentTheme = newValue.rawValue }
    }
}

// MARK: - Modern Design Style Helpers

struct ModernCardStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat = 16
    var isHovered: Bool = false

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(cardBackground)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(cardBorder, lineWidth: 1)
            }
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? (isHovered ? 0.35 : 0.20) : (isHovered ? 0.08 : 0.04)),
                radius: isHovered ? 12 : 6,
                x: 0,
                y: isHovered ? 4 : 2
            )
    }

    private var cardBackground: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.11, green: 0.11, blue: 0.13),
                        Color(red: 0.08, green: 0.08, blue: 0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.white,
                        Color(red: 0.98, green: 0.98, blue: 0.99)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    private var cardBorder: Color {
        if colorScheme == .dark {
            return isHovered ? Color.white.opacity(0.18) : Color.white.opacity(0.08)
        } else {
            return isHovered ? Color.black.opacity(0.15) : Color.black.opacity(0.06)
        }
    }
}

extension View {
    func modernCard(cornerRadius: CGFloat = 16, isHovered: Bool = false) -> some View {
        modifier(ModernCardStyle(cornerRadius: cornerRadius, isHovered: isHovered))
    }
}
