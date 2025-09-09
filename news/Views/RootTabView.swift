import SwiftUI

struct RootTabView: View {
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @State private var showEditSourcesWorld = false
    @State private var showEditSourcesSports = false
    @State private var showEditSourcesFinance = false
    @State private var showEditSourcesTech = false
    // ViewModels for each tab to pass to EditSourcesView
    @StateObject private var worldNewsVM = WorldNewsViewModel()
    @StateObject private var sportsVM = SportsViewModel()
    @StateObject private var financeVM = FinanceViewModel()
    @StateObject private var techVM = TechViewModel()

    var body: some View {
        TabView {
            VStack(spacing: 0) {
                HStack {
                    Button(action: { showEditSourcesWorld = true }) {
                        Image(systemName: "slider.horizontal.3")
                    }
                    Spacer()
                    Toggle(isOn: $isDarkMode) {
                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                    }
                    .toggleStyle(.button)
                }
                .padding(.horizontal)
                ArticleListView(articles: worldNewsVM.articles, errorMessage: worldNewsVM.errorMessage, onRefresh: { await worldNewsVM.fetchArticles() })
                    .task {
                        await worldNewsVM.fetchArticles()
                    }
            }
            .sheet(isPresented: $showEditSourcesWorld) {
                EditSourcesView(
                    sources: $worldNewsVM.sources,
                    onSourcesChanged: { Task { await worldNewsVM.fetchArticles() } }
                )
            }
            .tabItem {
                Label("World News", systemImage: "globe")
            }

            VStack(spacing: 0) {
                HStack {
                    Button(action: { showEditSourcesSports = true }) {
                        Image(systemName: "slider.horizontal.3")
                    }
                    Spacer()
                    Toggle(isOn: $isDarkMode) {
                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                    }
                    .toggleStyle(.button)
                }
                .padding(.horizontal)
                ArticleListView(articles: sportsVM.articles, errorMessage: sportsVM.errorMessage, onRefresh: { await sportsVM.fetchArticles() })
                    .task {
                        await sportsVM.fetchArticles()
                    }
            }
            .sheet(isPresented: $showEditSourcesSports) {
                EditSourcesView(
                    sources: $sportsVM.sources,
                    onSourcesChanged: { Task { await sportsVM.fetchArticles() } }
                )
            }
            .tabItem {
                Label("Sports", systemImage: "sportscourt")
            }

            VStack(spacing: 0) {
                HStack {
                    Button(action: { showEditSourcesFinance = true }) {
                        Image(systemName: "slider.horizontal.3")
                    }
                    Spacer()
                    Toggle(isOn: $isDarkMode) {
                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                    }
                    .toggleStyle(.button)
                }
                .padding(.horizontal)
                ArticleListView(articles: financeVM.articles, errorMessage: financeVM.errorMessage, onRefresh: { await financeVM.fetchArticles() })
                    .task {
                        await financeVM.fetchArticles()
                    }
            }
            .sheet(isPresented: $showEditSourcesFinance) {
                EditSourcesView(
                    sources: $financeVM.sources,
                    onSourcesChanged: { Task { await financeVM.fetchArticles() } }
                )
            }
            .tabItem {
                Label("Money", systemImage: "dollarsign.circle")
            }

            VStack(spacing: 0) {
                HStack {
                    Button(action: { showEditSourcesTech = true }) {
                        Image(systemName: "slider.horizontal.3")
                    }
                    Spacer()
                    Toggle(isOn: $isDarkMode) {
                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                    }
                    .toggleStyle(.button)
                }
                .padding(.horizontal)
                ArticleListView(articles: techVM.articles, errorMessage: techVM.errorMessage, onRefresh: { await techVM.fetchArticles() })
                    .task {
                        await techVM.fetchArticles()
                    }
            }
            .sheet(isPresented: $showEditSourcesTech) {
                EditSourcesView(
                    sources: $techVM.sources,
                    onSourcesChanged: { Task { await techVM.fetchArticles() } }
                )
            }
            .tabItem {
                Label("Tech", systemImage: "desktopcomputer")
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
} 