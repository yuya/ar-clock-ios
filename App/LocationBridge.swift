import Foundation
import CoreLocation
import WebKit

/// Web 側の `navigator.geolocation.getCurrentPosition` を、アプリの位置情報に差し替える。
/// こうすると許可の確認は iOS のもの1回だけになり、WebView 独自の確認が重ねて出ない。
final class LocationBridge: NSObject, WKScriptMessageHandler, CLLocationManagerDelegate {
    static let name = "geo"

    /// ページの読み込み前に入れるスクリプト
    static let script = """
    (function () {
      var cbs = {}, n = 0;
      window.__arGeo = function (id, ok, a, b) {
        var c = cbs[id]; delete cbs[id]; if (!c) return;
        if (ok) c.s({ coords: { latitude: a, longitude: b, accuracy: 100 }, timestamp: Date.now() });
        else if (c.e) c.e({ code: a, message: b, PERMISSION_DENIED: 1, POSITION_UNAVAILABLE: 2, TIMEOUT: 3 });
      };
      var geo = {
        getCurrentPosition: function (s, e) { var id = ++n; cbs[id] = { s: s, e: e }; window.webkit.messageHandlers.geo.postMessage(id); },
        watchPosition: function () { return 0; },
        clearWatch: function () {}
      };
      try { Object.defineProperty(navigator, 'geolocation', { value: geo, configurable: true }); } catch (_) {}
      window.__arNativeApp = true;
    })();
    """

    weak var webView: WKWebView?
    private let manager = CLLocationManager()
    private var pending: [Int] = []

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer   // 都道府県がわかれば足りる
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let id = message.body as? Int else { return }
        pending.append(id)
        proceed()
    }

    private func proceed() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            fail(code: 1, message: "denied")
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if !pending.isEmpty && manager.authorizationStatus != .notDetermined { proceed() }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let c = locations.last?.coordinate else { return }
        flush("true, \(c.latitude), \(c.longitude)")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        fail(code: 2, message: "unavailable")
    }

    private func fail(code: Int, message: String) {
        flush("false, \(code), '\(message)'")
    }

    private func flush(_ args: String) {
        let ids = pending
        pending.removeAll()
        for id in ids {
            webView?.evaluateJavaScript("window.__arGeo && window.__arGeo(\(id), \(args));", completionHandler: nil)
        }
    }
}
