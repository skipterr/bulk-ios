import Foundation
#if os(iOS)
import UIKit
#endif

// Обходной путь связи приложения с виджетом без App Group (её не даёт бесплатный Apple ID):
// именованный буфер обмена, общий для приложений одного разработчика.
// Не путать с обычным буфером «Скопировать/Вставить» — туда ничего не попадает.
enum SharedBridge {
    #if os(iOS)
    private static let board = UIPasteboard(name: UIPasteboard.Name("com.bulk.shared.state"), create: true)
    private static let type = "com.bulk.state"

    static func write(_ data: Data) {
        board?.setData(data, forPasteboardType: type)
    }

    static func read() -> Data? {
        board?.data(forPasteboardType: type)
    }

    // Запасная копия ключа Gemini: переживает переустановку через Sideloadly.
    private static let keyBoard = UIPasteboard(name: UIPasteboard.Name("com.bulk.shared.key"), create: true)

    static var savedKey: String? {
        get { keyBoard?.string }
        set { keyBoard?.string = newValue }
    }
    #else
    static func write(_ data: Data) {}
    static func read() -> Data? { nil }
    static var savedKey: String? { get { nil } set {} }
    #endif

    /// Для диагностики: видно ли из этого процесса хоть что-то в общем буфере.
    static var hasData: Bool { read() != nil }
}
