import SwiftUI

/// Tema tampilan. Hanya "Nest" yang gratis; sisanya bagian dari ClipNest Pro.
enum AppTheme: String, CaseIterable, Identifiable {
    case nest, midnight, sakura, forest, mono

    var id: String { rawValue }

    var name: String {
        switch self {
        case .nest: return "Nest"
        case .midnight: return "Midnight"
        case .sakura: return "Sakura"
        case .forest: return "Forest"
        case .mono: return "Mono"
        }
    }

    var accent: Color {
        switch self {
        case .nest: return Color(red: 0.95, green: 0.55, blue: 0.18)
        case .midnight: return Color(red: 0.35, green: 0.50, blue: 0.95)
        case .sakura: return Color(red: 0.93, green: 0.40, blue: 0.60)
        case .forest: return Color(red: 0.20, green: 0.70, blue: 0.45)
        case .mono: return Color(white: 0.55)
        }
    }

    /// Tema premium (butuh Pro). Default "nest" gratis.
    var isProOnly: Bool { self != .nest }
}

/// Preferensi ringan (tema, dll). Dinamai AppSettings agar tidak bentrok
/// dengan scene `Settings` milik SwiftUI.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var themeID: String {
        didSet { UserDefaults.standard.set(themeID, forKey: "clipnest.theme") }
    }

    private init() {
        themeID = UserDefaults.standard.string(forKey: "clipnest.theme") ?? AppTheme.nest.rawValue
    }

    var theme: AppTheme {
        get { AppTheme(rawValue: themeID) ?? .nest }
        set { themeID = newValue.rawValue }
    }
}
