import SwiftUI
import WidgetKit

// Виджеты iOS не умеют обычную анимацию, но умеют крутить «стрелку часов» сами,
// без участия приложения. На этом и держится движение Булька.

extension View {
    func clockSpin(_ period: TimeInterval, anchor: UnitPoint = .center) -> some View {
        _clockHandRotationEffect(.custom(period), in: .current, anchor: anchor)
    }
}

/// Покадровая анимация: каждый кадр закрыт маской-клином, клинья крутятся по кругу,
/// и в каждый момент над картинкой оказывается ровно один из них.
struct Flipbook<Frame: View>: View {
    let count: Int
    let period: TimeInterval
    let frame: (Int) -> Frame

    init(count: Int, period: TimeInterval, @ViewBuilder frame: @escaping (Int) -> Frame) {
        self.count = count
        self.period = period
        self.frame = frame
    }

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                frame(i).mask(FrameGate(index: i, count: count, period: period))
            }
        }
    }
}

private struct WedgeShape: Shape {
    let count: Int

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = Double(min(rect.width, rect.height)) / 2
        let step = 2 * Double.pi / Double(count)
        let start = -Double.pi / 2 - step / 2
        var p = Path()
        p.move(to: c)
        for k in 0...24 {
            let a = start + step * Double(k) / 24
            p.addLine(to: CGPoint(x: Double(c.x) + r * cos(a), y: Double(c.y) + r * sin(a)))
        }
        p.closeSubpath()
        return p
    }
}

private struct FrameGate: View {
    let index: Int
    let count: Int
    let period: TimeInterval

    var body: some View {
        GeometryReader { g in
            // Центр вращения далеко внизу: клин проходит над кадром почти мгновенно.
            let r = max(g.size.width, g.size.height) * 6 + 200
            WedgeShape(count: count)
                .fill(Color.black)
                .frame(width: r * 2, height: r * 2)
                .rotationEffect(.radians(-2 * Double.pi * Double(index) / Double(count)))
                .clockSpin(period)
                .position(x: g.size.width / 2, y: g.size.height / 2 + r * 0.6)
        }
    }
}
