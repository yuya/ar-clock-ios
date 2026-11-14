import SwiftUI

/// 設定ボタン。つかんで動かせて、離すといちばん近い画面の角に吸い付く。
/// しばらく触れないと薄くなる（Web 版と同じふるまい）
struct GearButton: View {
    let label: String
    let dimmed: Bool
    let onTap: () -> Void
    let onTouch: () -> Void

    @AppStorage("menuPos") private var corner = "tr"
    @State private var drag: CGSize = .zero
    @State private var pressed = false

    private var alignment: Alignment {
        switch corner {
        case "tl": return .topLeading
        case "bl": return .bottomLeading
        case "br": return .bottomTrailing
        default: return .topTrailing
        }
    }

    var body: some View {
        GeometryReader { geo in
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .scaleEffect(pressed ? 1.12 : 1)
                .opacity(dimmed && !pressed ? 0.4 : 1)
                .contentShape(Circle().inset(by: -12))   // 指が少しずれても拾う
                .offset(drag)
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { v in
                            if !pressed { pressed = true; onTouch() }
                            if hypot(v.translation.width, v.translation.height) >= 8 { drag = v.translation }
                        }
                        .onEnded { v in
                            pressed = false
                            let moved = hypot(v.translation.width, v.translation.height) >= 8
                            guard moved else {
                                drag = .zero
                                onTap()
                                return
                            }
                            // 離した位置に近い角へ
                            let w = geo.size.width, h = geo.size.height
                            let x0: CGFloat = corner.hasSuffix("l") ? 22 : w - 22
                            let y0: CGFloat = corner.hasPrefix("t") ? 22 : h - 22
                            let x = x0 + v.translation.width, y = y0 + v.translation.height
                            let next = (y < h / 2 ? "t" : "b") + (x < w / 2 ? "l" : "r")
                            Haptics.select()
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                                corner = next
                                drag = .zero
                            }
                        }
                )
                .animation(.easeOut(duration: 0.4), value: dimmed)
                .animation(.easeOut(duration: 0.12), value: pressed)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
                .accessibilityElement()
                .accessibilityLabel(label)
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { onTap() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
