import SwiftUI
import WebKit

struct ReaderModeView: View {
    let url: URL
    @State private var extractedHTML: String? = nil
    @State private var isLoading = true
    @State private var error: String? = nil
    @StateObject private var webViewStore = WebViewStore()
    
    var body: some View {
        Group {
            if let html = extractedHTML {
                ReaderWebView(html: html)
            } else if let error = error {
                Text(error).foregroundColor(.red).padding()
            } else {
                VStack {
                    Spacer()
                    ProgressView("Extracting article...")
                    Spacer()
                }
            }
        }
        .onAppear {
            loadAndExtract()
        }
    }
    
    private func loadAndExtract() {
        let request = URLRequest(url: url)
        webViewStore.webView.navigationDelegate = webViewStore
        webViewStore.onExtracted = { result in
            switch result {
            case .success(let html):
                self.extractedHTML = html
                self.isLoading = false
            case .failure(let err):
                self.error = err.localizedDescription
                self.isLoading = false
            }
        }
        webViewStore.webView.load(request)
    }
}

class WebViewStore: NSObject, ObservableObject, WKNavigationDelegate {
    let webView = WKWebView()
    var onExtracted: ((Result<String, Error>) -> Void)?
    private var didExtract = false
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard !didExtract else { return }
        didExtract = true
        // Load Readability.js from bundle
        guard let readabilityPath = Bundle.main.path(forResource: "Readability", ofType: "js") else {
            onExtracted?(.failure(NSError(domain: "ReaderMode", code: 2, userInfo: [NSLocalizedDescriptionKey: "Readability.js not found in bundle."])))
            return
        }
        do {
            let readabilityJS = try String(contentsOfFile: readabilityPath)
            let injectJS = "(function() {\n" + readabilityJS + "\nwindow.readerResult = (new Readability(document)).parse();\nreturn window.readerResult && window.readerResult.content ? window.readerResult.content : '';\n})();"
            webView.evaluateJavaScript(injectJS) { result, error in
                if let html = result as? String, !html.isEmpty {
                    self.onExtracted?(.success(html))
                } else {
                    self.onExtracted?(.failure(error ?? NSError(domain: "ReaderMode", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to extract article content."])))
                }
            }
        } catch {
            onExtracted?(.failure(error))
        }
    }
}

struct ReaderWebView: UIViewRepresentable {
    let html: String
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
} 