import SwiftUI
import WebKit

struct BrowserPreviewView: NSViewRepresentable {
    @ObservedObject var bridge: BrowserBridge

    func makeNSView(context: Context) -> WKWebView {
        bridge.webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
