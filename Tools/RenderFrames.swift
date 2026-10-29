import SwiftUI
import AppKit

// Рисует по 10 кадров Булька на каждое занятие (из них собираются шрифты для виджета)
// и иконку приложения.
// Запуск (на Mac): render <папка для кадров> [путь к icon.png]

struct BulkSprite: View {
    let action: BulkAction
    let f: FramePose

    var body: some View {
        let pose = action.pose
        let bodyW: CGFloat = 50, bodyH: CGFloat = 52
        BulkBody(eyes: f.eyes ?? action.eyes,
                 mouth: f.mouth ?? action.mouth,
                 dark: action == .inDark || action == .scared,
                 angry: action == .mad || action == .swear,
                 arms: f.arms ?? pose.arms,
                 holding: action.holding,
                 blush: 0)
            .frame(width: bodyW * pose.sx * CGFloat(f.sx), height: bodyH * pose.sy * CGFloat(f.sy))
            .rotationEffect(.degrees(pose.tilt + f.tilt), anchor: .bottom)
            .offset(x: CGFloat(f.dx), y: CGFloat(f.dy))
            .frame(width: 112, height: 80, alignment: .bottom)
    }
}

struct AppIconView: View {
    var body: some View {
        ZStack {
            Color(white: 0.16)
            BulkBody(eyes: .open, mouth: .flat, dark: false, angry: false, arms: .rest, holding: .none, blush: 0)
                .frame(width: 560, height: 590)
                .offset(y: 70)
        }
        .frame(width: 1024, height: 1024)
    }
}

// На облачном Mac нет видеокарты, поэтому рисуем через AppKit, а не ImageRenderer (он требует Metal).
@MainActor
func png<V: View>(_ view: V, width: CGFloat, height: CGFloat) throws -> Data {
    let rect = NSRect(x: 0, y: 0, width: width, height: height)
    let host = NSHostingView(rootView: view.frame(width: width, height: height, alignment: .topLeading))
    host.frame = rect
    host.layoutSubtreeIfNeeded()
    guard let rep = host.bitmapImageRepForCachingDisplay(in: rect) else {
        throw NSError(domain: "render", code: 1)
    }
    host.cacheDisplay(in: rect, to: rep)
    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "render", code: 2)
    }
    return data
}

@main
struct RenderFrames {
    @MainActor
    static func main() throws {
        _ = NSApplication.shared
        let args = CommandLine.arguments
        let out = URL(fileURLWithPath: args[1])
        try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        for action in BulkAction.allCases {
            for i in 0..<10 {
                let sprite = BulkSprite(action: action, f: action.framePose(i, of: 10, drunk: false))
                    .scaleEffect(3, anchor: .topLeading)
                try png(sprite, width: 336, height: 240)
                    .write(to: out.appendingPathComponent("\(action.rawValue)_\(i).png"))
            }
        }
        print("frames:", BulkAction.allCases.count * 10)

        if args.count > 2 {
            let iconURL = URL(fileURLWithPath: args[2])
            try FileManager.default.createDirectory(at: iconURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try png(AppIconView(), width: 1024, height: 1024).write(to: iconURL)
            print("icon:", iconURL.path)
        }
    }
}
