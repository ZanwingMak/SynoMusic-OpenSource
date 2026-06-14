import SwiftUI

/// 一种可选的强调色（accent）配方。
struct AccentPalette: Identifiable, Hashable {
    let id: String
    let name: String
    let lightHex: String
    let darkHex: String
    let gradientStart: String
    let gradientEnd: String

    /// 当前外观下的纯色 accent。
    func accent(in scheme: ColorScheme) -> Color {
        Color(hex: scheme == .dark ? darkHex : lightHex)
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: gradientStart), Color(hex: gradientEnd)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/// 配色管理：读写当前选中主题；持久化到 UserDefaults。
@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentID: String {
        didSet { UserDefaults.standard.set(currentID, forKey: key); UserDefaults.standard.synchronize() }
    }
    @Published var appearance: AppearancePreference {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: appearanceKey); UserDefaults.standard.synchronize() }
    }

    private let key = "syno.theme.id"
    private let appearanceKey = "syno.theme.appearance"

    init() {
        self.currentID = UserDefaults.standard.string(forKey: "syno.theme.id") ?? Self.defaultPalette.id
        let raw = UserDefaults.standard.string(forKey: "syno.theme.appearance") ?? AppearancePreference.system.rawValue
        self.appearance = AppearancePreference(rawValue: raw) ?? .system
    }

    var current: AccentPalette {
        Self.palettes.first(where: { $0.id == currentID }) ?? Self.defaultPalette
    }

    static let defaultPalette = AccentPalette(
        id: "magenta",
        name: "夜色品红",
        lightHex: "EF6BA9",
        darkHex: "F478B8",
        gradientStart: "F26BA8",
        gradientEnd: "9F61F2"
    )

    static let palettes: [AccentPalette] = [
        defaultPalette,
        .init(id: "ocean", name: "深蓝海", lightHex: "3478F6", darkHex: "5B9CFF",
              gradientStart: "3478F6", gradientEnd: "30C7E4"),
        .init(id: "aurora", name: "极光绿", lightHex: "30B27F", darkHex: "3FD49C",
              gradientStart: "30B27F", gradientEnd: "5BD4A4"),
        .init(id: "sunset", name: "落日橙", lightHex: "FF8A3D", darkHex: "FFA45C",
              gradientStart: "FF8A3D", gradientEnd: "FF5E62"),
        .init(id: "amethyst", name: "紫水晶", lightHex: "9B6BE6", darkHex: "B485F1",
              gradientStart: "9B6BE6", gradientEnd: "5D5BFF"),
        .init(id: "rose", name: "玫瑰红", lightHex: "E63E5C", darkHex: "FF6385",
              gradientStart: "E63E5C", gradientEnd: "FF8AB2"),
        .init(id: "teal", name: "深青", lightHex: "1FA9A0", darkHex: "3CC9BD",
              gradientStart: "1FA9A0", gradientEnd: "44B5C9"),
        .init(id: "graphite", name: "石墨灰", lightHex: "636366", darkHex: "8E8E93",
              gradientStart: "636366", gradientEnd: "AEAEB2")
    ]
}

/// Light / Dark / 跟随系统。
enum AppearancePreference: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

extension Color {
    /// 6 位 hex → Color。无 #；忽略错误。
    init(hex: String) {
        var s = hex.uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let value = UInt32(s, radix: 16) else {
            self = .gray
            return
        }
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
