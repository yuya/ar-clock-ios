import SwiftUI
import AVFoundation

@main
struct ARClockApp: App {
    init() {
        ARClockApp.activateAudio()
        // 裏から戻るとき、OS に閉じられた音の出口を開き直す（開き直さないと、戻ったあと BGM が鳴らない）
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
            ARClockApp.activateAudio()
        }
        // 電話などで音が中断されたあとも開き直す
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { note in
            if let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
               AVAudioSession.InterruptionType(rawValue: raw) == .ended {
                ARClockApp.activateAudio()
            }
        }
    }

    /// 消音スイッチが入っていても BGM と時報を鳴らす
    static func activateAudio() {
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
