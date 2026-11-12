import SwiftUI
import WebKit

/// Web アプリ（ar-clock）をそのまま全画面で動かす入れ物
struct WebScreen: UIViewRepresentable {
    let bridge: WebBridge
    var autostart = false

    func makeCoordinator() -> Coordinator { Coordinator(bridge: bridge, autostart: autostart) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true                    // 動画を全画面プレーヤーにしない
        config.mediaTypesRequiringUserActionForPlayback = []       // 触らなくても映像と音を始められる

        let root = Bundle.main.url(forResource: "Web", withExtension: nil) ?? Bundle.main.bundleURL
        config.setURLSchemeHandler(AppSchemeHandler(root: root), forURLScheme: AppSchemeHandler.scheme)

        let location = context.coordinator.location
        config.userContentController.add(location, name: LocationBridge.name)
        config.userContentController.add(bridge, name: WebBridge.name)
        config.userContentController.addUserScript(
            WKUserScript(source: LocationBridge.script, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        )

        let view = WKWebView(frame: .zero, configuration: config)
        location.webView = view
        bridge.webView = view
        view.uiDelegate = context.coordinator
        view.navigationDelegate = context.coordinator
        view.isOpaque = false
        view.backgroundColor = .black
        view.scrollView.backgroundColor = .black
        view.scrollView.bounces = false
        view.scrollView.isScrollEnabled = false
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.allowsLinkPreview = false
        if #available(iOS 16.4, *) { view.isInspectable = true }   // Mac の Safari からデバッグできるようにする
        view.load(URLRequest(url: AppSchemeHandler.start))
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
        let location = LocationBridge()
        let bridge: WebBridge
        let autostart: Bool

        init(bridge: WebBridge, autostart: Bool) {
            self.bridge = bridge
            self.autostart = autostart
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if autostart {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [bridge] in bridge.autostart() }
            }
        }

        /// カメラの許可は iOS の確認（初回の1回）に任せ、WebView 独自の確認は出さない
        func webView(_ webView: WKWebView,
                     requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                     initiatedByFrame frame: WKFrameInfo,
                     type: WKMediaCaptureType,
                     decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(origin.protocol == AppSchemeHandler.scheme ? .grant : .deny)
        }

        /// アプリ内の画面以外へは移動させない（外部リンクは Safari で開く）
        func webView(_ webView: WKWebView,
                     decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = action.request.url else { return decisionHandler(.cancel) }
            if url.scheme == AppSchemeHandler.scheme || url.scheme == "about" || url.scheme == "blob" || url.scheme == "data" {
                decisionHandler(.allow)
            } else {
                if action.navigationType == .linkActivated { UIApplication.shared.open(url) }
                decisionHandler(action.targetFrame?.isMainFrame == false ? .allow : .cancel)
            }
        }

        /// WebView の中身が落ちたら読み直す
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            webView.load(URLRequest(url: AppSchemeHandler.start))
        }
    }
}
