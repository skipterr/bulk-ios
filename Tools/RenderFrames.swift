import SwiftUI
import AppKit

// Рисует по 10 кадров Булька на каждое занятие — из них потом собираются шрифты для виджета.
// Запуск (на Mac): render <папка для png>

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

@main
struct RenderFrames {
    @MainActor
    static func main() throws {
        _ = NSApplication.shared
        let out = URL(fileURLWithPath: CommandLine.arguments[1])
        try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        // На облачном Mac нет видеокарты, поэтому рисуем через AppKit, а не ImageRenderer (он требует Metal).
        let size = NSRect(x: 0, y: 0, width: 336, height: 240)
        for action in BulkAction.allCases {
            for i in 0..<10 {
                let sprite = BulkSprite(action: action, f: action.framePose(i, of: 10, drunk: false))
                    .scaleEffect(3, anchor: .topLeading)
                    .frame(width: 336, height: 240, alignment: .topLeading)
                let host = NSHostingView(rootView: sprite)
                host.frame = size
                host.layoutSubtreeIfNeeded()
                guard let rep = host.bitmapImageRepForCachingDisplay(in: size) else {
                    throw NSError(domain: "render", code: 1, userInfo: [NSLocalizedDescriptionKey: "\(action) \(i)"])
                }
                host.cacheDisplay(in: size, to: rep)
                guard let png = rep.representation(using: .png, properties: [:]) else {
                    throw NSError(domain: "render", code: 2, userInfo: [NSLocalizedDescriptionKey: "\(action) \(i)"])
                }
                try png.write(to: out.appendingPathComponent("\(action.rawValue)_\(i).png"))
            }
        }
        print("frames:", BulkAction.allCases.count * 10)
    }
}
