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
                Button { Haptics.tap(); showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding(.trailing, 16)
                .padding(.top, 8)
                .accessibilityLabel(bridge.schema?.title ?? "Settings")
            }
        }
        .background(Color.black)
        .sheet(isPresented: $showSettings) {
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
