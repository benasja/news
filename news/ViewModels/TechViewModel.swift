import Foundation

@MainActor
class TechViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var errorMessage: String? = nil
    @Published var sources: [FeedSource] = [] {
        didSet { saveSources() }
    }
    
    private let userDefaultsKey = "TechFeedSources"
    
    init() {
        loadSources()
    }
    
    func loadSources() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let saved = try? JSONDecoder().decode([FeedSource].self, from: data) {
            sources = saved
        } else {
            sources = [
                FeedSource(name: "The Verge", url: "https://www.theverge.com/rss/index.xml"),
                FeedSource(name: "Wired", url: "https://www.wired.com/feed/rss"),
                FeedSource(name: "TechRadar", url: "https://www.techradar.com/rss"),
                FeedSource(name: "Ars Technica", url: "https://feeds.arstechnica.com/arstechnica/index"),
                FeedSource(name: "TechCrunch", url: "https://techcrunch.com/feed/"),
                FeedSource(name: "Engadget", url: "https://www.engadget.com/rss.xml"),
                FeedSource(name: "9to5Mac", url: "https://9to5mac.com/feed/"),
                FeedSource(name: "Hackaday", url: "https://hackaday.com/feed/"),
                FeedSource(name: "Reddit r/tech", url: "https://www.reddit.com/r/tech/.rss"),
                FeedSource(name: "Reddit r/technology", url: "https://www.reddit.com/r/technology/.rss"),
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
