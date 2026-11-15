import Foundation
import WebKit

/// Web 側が渡してくる「設定の一覧」。設定パネルの中身をそのまま写したもの
struct Schema: Decodable {
    let running: Bool
    let camera: String?          // user / environment（カメラを映していないときは nil）
    let title: String
    let close: String
    let groups: [Group]

    struct Group: Decodable {
        let title: String
        let items: [Item]
    }

    struct Item: Decodable {
        let t: String              // buttons / label / slider / note
        let cols: Int?
        let buttons: [Btn]?
        let text: String?
        let id: String?
        let min: Double?
        let max: Double?
        let step: Double?
        let value: Double?
        let lo: String?
        let hi: String?
    }

    struct Btn: Decodable, Identifiable {
        let id: String
        let label: String
        let on: Bool
        let file: Bool?
    }
}

/// Web（window.ARClock）との窓口。一覧を受け取り、押す・動かすを伝える
final class WebBridge: NSObject, ObservableObject, WKScriptMessageHandler {
    static let name = "arclock"
    static let hapticName = "haptic"
    static let uiName = "ui"

    @Published var schema: Schema?
    /// しばらく触れていないので設定ボタンを薄くする
    @Published var dimmed = false
    weak var webView: WKWebView?

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == WebBridge.uiName {
            let m = message.body as? String ?? ""
            if m == "dim" { dimmed = true } else if m == "wake" { dimmed = false }
            return
        }
        if message.name == WebBridge.hapticName {
            Haptics.play(message.body as? String ?? "tap")
            return
        }
        guard let text = message.body as? String, let data = text.data(using: .utf8) else { return }
        if let decoded = try? JSONDecoder().decode(Schema.self, from: data) {
            schema = decoded
        }
    }

    /// 前面・背面カメラの切り替え
    func flip() {
        run("window.ARClock && window.ARClock.flip && window.ARClock.flip();")
    }

    func tap(_ id: String) {
        run("window.ARClock && window.ARClock.tap(\(quoted(id)));")
    }

    func slide(_ id: String, _ value: Double) {
        run("window.ARClock && window.ARClock.slide(\(quoted(id)), \(value));")
    }

    /// 設定ボタンに触れた：薄くなるまでの時間を数え直す
    func wake() {
        dimmed = false
        run("window.ARClock && window.ARClock.wake && window.ARClock.wake();")
    }

    /// 自動確認用：最初の画面をサンプル映像で通す
    func autostart() {
        run("window.ARClock && window.ARClock.start(false);")
    }

    private func run(_ js: String) {
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }

    private func quoted(_ s: String) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: [s])) ?? Data("[\"\"]".utf8)
        let text = String(data: data, encoding: .utf8) ?? "[\"\"]"
        return String(text.dropFirst().dropLast())
    }
}
