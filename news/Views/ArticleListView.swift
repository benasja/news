import SwiftUI

struct ArticleListView: View {
    let articles: [Article]
    let errorMessage: String?
    @State private var selectedArticle: Article?
    var onRefresh: (() async -> Void)? = nil
    var isLoading: Bool = false
    var body: some View {
        if let errorMessage = errorMessage {
            Text(errorMessage)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding()
        } else if isLoading {
            VStack {
                Spacer()
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
                Spacer()
            }
        } else {
            List(articles) { article in
                Button(action: {
                    selectedArticle = article
                }) {
                    ArticleRowView(article: article)
                }
            }
            .listStyle(PlainListStyle())
            .refreshable {
                await onRefresh?()
            }
            .sheet(item: $selectedArticle, onDismiss: { selectedArticle = nil }) { article in
                ArticleDetailView(url: article.link)
            }
        }
    }
} 