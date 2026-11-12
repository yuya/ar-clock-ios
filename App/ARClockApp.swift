import SwiftUI
import AVFoundation

@main
struct ARClockApp: App {
    init() {
        // 消音スイッチが入っていても BGM と時報を鳴らす
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
                .background(Color.black)
                .onAppear { UIApplication.shared.isIdleTimerDisabled = true }   // 時計なので画面を消さない
        }
    }
}
