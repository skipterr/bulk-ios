import SwiftUI
import AppKit

// Рисует по 10 кадров Булька на каждое занятие — из них потом собираются шрифты для виджета.
// Запуск (на Mac): render <папка для png>

struct BulkSprite: View {
    let action: BulkAction
    let f: FramePose

    var body: some View {
        let pose = action.pose
        let bodyW: CGFloat = 64, bodyH: CGFloat = 40
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
        let out = URL(fileURLWithPath: CommandLine.arguments[1])
        try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        for action in BulkAction.allCases {
            for i in 0..<10 {
                let renderer = ImageRenderer(content: BulkSprite(action: action, f: action.framePose(i, of: 10, drunk: false)))
                renderer.scale = 3
                guard let cg = renderer.cgImage,
                      let png = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]) else {
                    throw NSError(domain: "render", code: 1, userInfo: [NSLocalizedDescriptionKey: "\(action) \(i)"])
                }
                try png.write(to: out.appendingPathComponent("\(action.rawValue)_\(i).png"))
            }
        }
        print("frames:", BulkAction.allCases.count * 10)
    }
}
