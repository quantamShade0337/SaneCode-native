import Foundation
import Combine
import WebKit

final class BrowserBridge: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var currentURL: String = ""
    @Published var title: String = ""

    let webView = WKWebView()

    override init() {
        super.init()
        webView.navigationDelegate = self
    }

    func load(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        webView.load(URLRequest(url: url))
        currentURL = urlString
    }

    func reload() {
        webView.reload()
    }

    func goBack() {
        webView.goBack()
    }

    func goForward() {
        webView.goForward()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        currentURL = webView.url?.absoluteString ?? currentURL
        webView.evaluateJavaScript("document.title") { [weak self] result, _ in
            self?.title = result as? String ?? ""
        }
    }
}
