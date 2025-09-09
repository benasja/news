import SwiftUI
import SafariServices

struct ArticleDetailView: View {
    let url: URL
    @State private var showReader = false
    
    var body: some View {
        NavigationView {
            SafariView(url: url)
                .edgesIgnoringSafeArea(.bottom)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showReader = true }) {
                            Label("Reader Mode", systemImage: "doc.text.magnifyingglass")
                        }
                    }
                }
                .sheet(isPresented: $showReader) {
                    ReaderModeView(url: url)
                }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
} 