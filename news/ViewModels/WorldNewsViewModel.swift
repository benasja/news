import Foundation

@MainActor
class WorldNewsViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var errorMessage: String? = nil
    @Published var sources: [FeedSource] = [] {
        didSet { saveSources() }
    }
    
    private let userDefaultsKey = "WorldNewsFeedSources"
    
    init() {
        loadSources()
    }
    
    func loadSources() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let saved = try? JSONDecoder().decode([FeedSource].self, from: data) {
            sources = saved
        } else {
            sources = [
                FeedSource(name: "Bellingcat", url: "https://www.bellingcat.com/feed/"),
                FeedSource(name: "BBC World", url: "https://feeds.bbci.co.uk/news/world/rss.xml"),
                FeedSource(name: "The Guardian World", url: "https://www.theguardian.com/world/rss"),
                FeedSource(name: "Al Jazeera", url: "https://www.aljazeera.com/xml/rss/all.xml"),
                FeedSource(name: "The Economist", url: "https://www.economist.com/international/rss.xml"),
                FeedSource(name: "Reddit r/worldnews", url: "https://www.reddit.com/r/worldnews/.rss"),
                FeedSource(name: "Reddit r/europe", url: "https://www.reddit.com/r/europe/.rss"),
                FeedSource(name: "Reddit r/geopolitics", url: "https://www.reddit.com/r/geopolitics/.rss")
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
