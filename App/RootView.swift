import SwiftUI

/// 全画面の Web と、その上に置くアプリ側の設定ボタン
struct RootView: View {
    @StateObject private var bridge = WebBridge()
    @State private var showSettings = false

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
