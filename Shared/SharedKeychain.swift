import Foundation
import Security

// Второй обходной путь связи приложения и виджета: общая группа в связке ключей.
// Бесплатный профиль Apple обычно разрешает группы вида «КОМАНДА.что-угодно»,
// поэтому имя группы собираем из префикса команды, который узнаём у самой связки.
enum SharedKeychain {
    private static let account = "bulk.state"
    private static let service = "com.bulk.shared"
    /// Код последней ошибки (для диагностики на виджете), 0 — всё хорошо.
    static var lastStatus: OSStatus = 0

    /// Префикс команды (Team ID): кладём пробный элемент и смотрим, в какую группу он попал.
    static let teamPrefix: String? = {
        let probe: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: "com.bulk.probe",
                                    kSecAttrAccount as String: "probe"]
        SecItemDelete(probe as CFDictionary)
        var add = probe
        add[kSecValueData as String] = Data("1".utf8)
        add[kSecReturnAttributes as String] = true
        var out: AnyObject?
        guard SecItemAdd(add as CFDictionary, &out) == errSecSuccess,
              let attrs = out as? [String: Any],
              let group = attrs[kSecAttrAccessGroup as String] as? String,
              let prefix = group.split(separator: ".").first else { return nil }
        return String(prefix)
    }()

    private static var group: String? { teamPrefix.map { "\($0).com.bulk.shared" } }

    private static func query() -> [String: Any]? {
        guard let group else { return nil }
        return [kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecAttrAccessGroup as String: group]
    }

    static func write(_ data: Data) {
        guard var q = query() else { lastStatus = -1; return }
        let update = [kSecValueData as String: data] as CFDictionary
        var status = SecItemUpdate(q as CFDictionary, update)
        if status == errSecItemNotFound {
            q[kSecValueData as String] = data
            q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            status = SecItemAdd(q as CFDictionary, nil)
        }
        lastStatus = status
    }

    static func read() -> Data? {
        guard var q = query() else { lastStatus = -1; return nil }
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: AnyObject?
        lastStatus = SecItemCopyMatching(q as CFDictionary, &out)
        return out as? Data
    }
}
