import Foundation

// Общая «память» приложения и виджета (App Group).
// Sideloadly при установке может переименовать группу под твой Apple ID,
// поэтому настоящее имя читаем из профиля, вшитого в приложение.
enum SharedGroup {
    static let id: String? = {
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .isoLatin1),
              let start = text.range(of: "<?xml"),
              let end = text.range(of: "</plist>") else { return nil }
        let xml = Data(text[start.lowerBound..<end.upperBound].utf8)
        guard let plist = try? PropertyListSerialization.propertyList(from: xml, format: nil) as? [String: Any],
              let entitlements = plist["Entitlements"] as? [String: Any],
              let groups = entitlements["com.apple.security.application-groups"] as? [String] else { return nil }
        return groups.first
    }()

    static var isShared: Bool {
        guard let id else { return false }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) != nil
    }

    static var defaults: UserDefaults {
        if isShared, let id, let d = UserDefaults(suiteName: id) { return d }
        return .standard
    }
}
