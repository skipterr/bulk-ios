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

        // превью виджета: граффити всех цветов на стене
        let tags = WallTag.texts.prefix(5).enumerated().map { i, t in
            WallTag(text: t, x: [0.2, 0.5, 0.82, 0.3, 0.62][i], y: [0.3, 0.22, 0.35, 0.62, 0.55][i],
                    color: i, tilt: [-8, 5, -4, 7, -10][i], createdAt: .now)
        }
        let scene = BulkScene(frame: BulkFrame(action: .graffiti, x: 0.42, pose: FramePose(arms: .wave), light: true, shoeX: 0.9),
                              phrase: "йоу", tipsy: 0, gifts: ["poster", "cactus"], tags: tags)
            .frame(width: 364, height: 170)
            .scaleEffect(3, anchor: .topLeading)
        try png(scene, width: 1092, height: 510).write(to: out.appendingPathComponent("widget.png"))

        if args.count > 2 {
            let iconURL = URL(fileURLWithPath: args[2])
            try FileManager.default.createDirectory(at: iconURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try png(AppIconView(), width: 1024, height: 1024).write(to: iconURL)
            print("icon:", iconURL.path)
        }
    }
}
