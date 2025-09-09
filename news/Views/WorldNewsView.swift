import SwiftUI

struct WorldNewsView: View {
    @StateObject private var viewModel = WorldNewsViewModel()
    @State private var showEditSources = false
    @State private var cachedArticles: [Article] = []
    var body: some View {
        ArticleListView(
            articles: !viewModel.articles.isEmpty ? viewModel.articles : cachedArticles,
            errorMessage: viewModel.errorMessage,
            onRefresh: {
                await viewModel.fetchArticles()
                cachedArticles = viewModel.articles
            },
            isLoading: viewModel.articles.isEmpty && viewModel.errorMessage == nil
        )
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showEditSources = true }) {
                    Image(systemName: "slider.horizontal.3")
                }
            }
        }
        .sheet(isPresented: $showEditSources) {
            EditSourcesView(sources: $viewModel.sources, onSourcesChanged: { Task { await viewModel.fetchArticles(); cachedArticles = viewModel.articles } })
        }
        .task {
            if viewModel.articles.isEmpty {
                await viewModel.fetchArticles()
                cachedArticles = viewModel.articles
            }
        }
    }
} 