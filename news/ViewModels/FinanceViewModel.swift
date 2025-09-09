import Foundation

@MainActor
class FinanceViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var errorMessage: String? = nil
    @Published var sources: [FeedSource] = [] {
        didSet { saveSources() }
    }
    
    private let userDefaultsKey = "FinanceFeedSources"
    
    init() {
        loadSources()
    }
    
    func loadSources() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let saved = try? JSONDecoder().decode([FeedSource].self, from: data) {
            sources = saved
        } else {
            sources = [
                FeedSource(name: "Coindesk", url: "https://www.coindesk.com/arc/outboundfeeds/rss/?outputType=xml"),
                FeedSource(name: "CNBC Markets", url: "https://www.cnbc.com/id/100003114/device/rss/rss.html"),
                FeedSource(name: "Reddit r/wallstreetbets", url: "https://www.reddit.com/r/wallstreetbets/.rss"),
                FeedSource(name: "Reddit r/cryptocurrency", url: "https://www.reddit.com/r/cryptocurrency/.rss"),
                FeedSource(name: "Reddit r/stocks", url: "https://www.reddit.com/r/stocks/.rss"),
            ]
            saveSources()
        }
    }
    
    func saveSources() {
        if let data = try? JSONEncoder().encode(sources) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    func addSource(name: String, url: String) {
        let newSource = FeedSource(name: name, url: url)
        sources.append(newSource)
        Task {
            await fetchArticles()
        }
    }
    
    func removeSource(at offsets: IndexSet) {
        sources.remove(atOffsets: offsets)
        Task {
            await fetchArticles()
        }
    }
    
    func updateSource(_ source: FeedSource, name: String, url: String) {
        if let idx = sources.firstIndex(where: { $0.id == source.id }) {
            sources[idx].name = name
            sources[idx].url = url
        }
    }
    
    func fetchArticles() async {
        let feeds = sources.compactMap { source in
            if let url = URL(string: source.url) { return (url: url, sourceName: source.name) }
            return nil
        }
        do {
            let articles = await RSSParser.fetchArticles(from: feeds)
            if articles.isEmpty {
                self.errorMessage = "Failed to load articles. Please try again later."
            }
            self.articles = articles
        } catch {
            self.errorMessage = "Failed to load articles. Please try again later."
        }
    }
} 
