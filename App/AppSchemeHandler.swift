import Foundation
import WebKit
import UniformTypeIdentifiers

/// アプリに同梱した Web 一式（Web フォルダ）を `arclock://app/…` として配る。
/// file:// ではなく独自スキームにするのは、カメラなど「安全な接続」が前提の機能を使うため。
/// 動画は途中から読む要求（Range）が来るので、その範囲だけを返す。
final class AppSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "arclock"
    static let start = URL(string: "arclock://app/index.html")!

    private let root: URL

    init(root: URL) {
        self.root = root.standardizedFileURL
    }

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url else {
            task.didFailWithError(URLError(.badURL))
            return
        }
        var path = url.path
        if path.isEmpty || path == "/" { path = "/index.html" }
        let file = root.appendingPathComponent(String(path.dropFirst())).standardizedFileURL

        guard file.path.hasPrefix(root.path),
              let attrs = try? FileManager.default.attributesOfItem(atPath: file.path),
              let size = (attrs[.size] as? NSNumber)?.intValue,
              let handle = try? FileHandle(forReadingFrom: file) else {
            respond(task, url: url, status: 404, headers: ["Content-Type": "text/plain"], body: Data("Not found".utf8))
            return
        }
        defer { try? handle.close() }

        var headers = [
            "Content-Type": mimeType(for: file),
            "Accept-Ranges": "bytes",
            "Cache-Control": "no-cache",
            "Access-Control-Allow-Origin": "*"
        ]

        if let range = parseRange(task.request.value(forHTTPHeaderField: "Range"), size: size) {
            try? handle.seek(toOffset: UInt64(range.lowerBound))
            let data = (try? handle.read(upToCount: range.count)) ?? Data()
            headers["Content-Range"] = "bytes \(range.lowerBound)-\(range.upperBound - 1)/\(size)"
            headers["Content-Length"] = String(data.count)
            respond(task, url: url, status: 206, headers: headers, body: data)
        } else {
            let data = (try? handle.readToEnd()) ?? Data()
            headers["Content-Length"] = String(data.count)
            respond(task, url: url, status: 200, headers: headers, body: data)
        }
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}

    private func respond(_ task: WKURLSchemeTask, url: URL, status: Int, headers: [String: String], body: Data) {
        guard let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers) else {
            task.didFailWithError(URLError(.unknown))
            return
        }
        task.didReceive(response)
        task.didReceive(body)
        task.didFinish()
    }

    /// "bytes=a-b" / "bytes=a-" / "bytes=-n" を、ファイル内の範囲に直す
    private func parseRange(_ header: String?, size: Int) -> Range<Int>? {
        guard let header = header, header.hasPrefix("bytes="), size > 0 else { return nil }
        let spec = header.dropFirst(6).split(separator: ",").first.map(String.init) ?? ""
        let parts = spec.split(separator: "-", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 2 else { return nil }
        if parts[0].isEmpty {
            guard let n = Int(parts[1]), n > 0 else { return nil }
            return max(0, size - n)..<size
        }
        guard let a = Int(parts[0]), a >= 0, a < size else { return nil }
        let b = min(Int(parts[1]) ?? (size - 1), size - 1)
        guard b >= a else { return nil }
        return a..<(b + 1)
    }

    private func mimeType(for file: URL) -> String {
        switch file.pathExtension.lowercased() {
        case "html": return "text/html; charset=utf-8"
        case "js": return "text/javascript; charset=utf-8"
        case "css": return "text/css; charset=utf-8"
        case "json": return "application/json"
        case "mp4": return "video/mp4"
        default: return UTType(filenameExtension: file.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
        }
    }
}
