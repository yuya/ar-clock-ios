import SwiftUI

/// 全画面の Web と、その上に置くアプリ側の設定ボタン
struct RootView: View {
    @StateObject private var bridge = WebBridge()
    @State private var showSettings = false
    @AppStorage("menuPos") private var gearCorner = "tr"

    private var args: [String] { ProcessInfo.processInfo.arguments }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            WebScreen(bridge: bridge, autostart: args.contains("-autostart"))
                .ignoresSafeArea()

            if bridge.schema?.running == true {
                GearButton(
                    label: bridge.schema?.title ?? "Settings",
                    dimmed: bridge.dimmed && !showSettings,
                    onTap: { Haptics.tap(); showSettings = true },
                    onTouch: { bridge.wake() }
                )
            }

            // 左下：前面・背面カメラの切り替え（カメラを映しているときだけ）
            if bridge.schema?.running == true, bridge.schema?.camera != nil {
                Button {
                    Haptics.tap(); bridge.wake(); bridge.flip()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                        .opacity(bridge.dimmed && !showSettings ? 0.4 : 1)
                        .contentShape(Circle().inset(by: -8))
                }
                .buttonStyle(.plain)
                .animation(.easeOut(duration: 0.4), value: bridge.dimmed)
                .padding(.leading, gearCorner == "bl" ? 16 + 54 : 16)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .accessibilityLabel("Switch camera")
            }
        }
        .background(Color.black)
        .sheet(isPresented: $showSettings, onDismiss: { bridge.wake() }) {
            SettingsView(bridge: bridge)
        }
        .onAppear {
            // 自動確認用：起動して少し待ってから設定を開く
            if args.contains("-openSettings") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 8) { showSettings = true }
            }
        }
    }
}
