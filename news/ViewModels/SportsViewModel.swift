import Foundation

@MainActor
class SportsViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var errorMessage: String? = nil
    @Published var sources: [FeedSource] = [] {
        didSet { saveSources() }
    }
    
    private let userDefaultsKey = "SportsFeedSources"
    
    init() {
        loadSources()
    }
    
    func loadSources() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let saved = try? JSONDecoder().decode([FeedSource].self, from: data) {
            sources = saved
        } else {
            // Default sources
            sources = [
                FeedSource(name: "ESPN NBA", url: "https://www.espn.com/espn/rss/nba/news"),
                FeedSource(name: "The Athletic NBA", url: "https://theathletic.com/rss/nba"),
                FeedSource(name: "Eurohoops", url: "https://www.eurohoops.net/en/feed/"),
                FeedSource(name: "ESPN F1", url: "https://www.espn.com/espn/rss/f1/news"),
                FeedSource(name: "BBC Sport Football", url: "https://feeds.bbci.co.uk/sport/football/rss.xml"),
                FeedSource(name: "The Guardian Football", url: "https://www.theguardian.com/football/rss"),
                FeedSource(name: "Sherdog", url: "https://www.sherdog.com/rss/news.xml")
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
