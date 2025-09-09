import Foundation

class RSSParser: NSObject, XMLParserDelegate {
    private var articles: [Article] = []
    private var currentElement = ""
    private var currentTitle: String = ""
    private var currentLink: String = ""
    private var currentPubDate: String = ""
    private var currentSourceName: String = ""
    private var currentID: UUID = UUID()
    private var feedSourceName: String = ""
    private var insideItem = false
    private var foundLinkHref: String? = nil

    // Support multiple date formats, including timezone abbreviations
    private let dateFormatters: [DateFormatter] = {
        let fmts = [
            "E, d MMM yyyy HH:mm:ss Z", // RSS 2.0
            "yyyy-MM-dd'T'HH:mm:ssZ",   // Atom
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ", // Atom with ms
            "yyyy-MM-dd'T'HH:mm:ssXXX", // Atom with timezone
            "yyyy-MM-dd'T'HH:mm:ss'Z'",   // Atom UTC
            "E, d MMM yyyy HH:mm:ss zzz" // With timezone abbreviation
        ]
        return fmts.map {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = $0
            return f
        }
    }()

    // Track failed sources for UI
    static var failedSources: [String: String] = [:]

    // Placeholder: Only allow popular Reddit posts (filter by title keyword)
    static var redditPopularKeywords: [String] = ["[Top]", "Megathread", "Daily", "Weekly", "Official", "Discussion", "News"]
    static var filterRedditPopularOnly: Bool = false // Set to true to enable filtering

    func parseFeed(url: URL, sourceName: String) async throws -> [Article] {
        self.feedSourceName = sourceName
        let (data, _) = try await URLSession.shared.data(from: url)
        let parser = XMLParser(data: data)
        parser.delegate = self
        articles = []
        parser.parse()
        if articles.isEmpty {
            RSSParser.failedSources[sourceName] = "No valid articles parsed."
        } else {
            RSSParser.failedSources.removeValue(forKey: sourceName)
        }
        // Filter for popular Reddit posts if enabled
        if RSSParser.filterRedditPopularOnly && url.host?.contains("reddit.com") == true {
            let filtered = articles.filter { article in
                RSSParser.redditPopularKeywords.contains { keyword in
                    article.title.localizedCaseInsensitiveContains(keyword)
                }
            }
            return filtered
        }
        return articles
    }

    static func fetchArticles(from feeds: [(url: URL, sourceName: String)]) async -> [Article] {
        await withTaskGroup(of: [Article].self) { group in
            for feed in feeds {
                group.addTask {
                    do {
                        return try await RSSParser().parseFeed(url: feed.url, sourceName: feed.sourceName)
                    } catch {
                        print("[RSSParser] Failed to fetch feed: \(feed.sourceName) - \(feed.url)\nError: \(error)")
                        failedSources[feed.sourceName] = "Network or parsing error."
                        return []
                    }
                }
            }
            var allArticles: [Article] = []
            for await articles in group {
                allArticles.append(contentsOf: articles)
            }
            return allArticles.sorted { $0.pubDate > $1.pubDate }
        }
    }

    // MARK: - XMLParserDelegate
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "item" || elementName == "entry" {
            insideItem = true
            currentTitle = ""
            currentLink = ""
            currentPubDate = ""
            foundLinkHref = nil
            currentID = UUID()
        }
        // Atom: <link href="..."/>
        if insideItem && elementName == "link", let href = attributeDict["href"], !href.isEmpty {
            foundLinkHref = href
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard insideItem else { return }
        switch currentElement {
        case "title": currentTitle += string
        case "link": currentLink += string
        case "pubDate", "updated": currentPubDate += string
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if (elementName == "item" || elementName == "entry") && insideItem {
            // Prefer Atom <link href="..."/> if available, else <link>...</link>
            let linkString = foundLinkHref ?? currentLink.trimmingCharacters(in: .whitespacesAndNewlines)
            if linkString.isEmpty || URL(string: linkString) == nil {
                print("[RSSParser] Skipped article in \(feedSourceName): missing or invalid link. Title: \(currentTitle)")
                insideItem = false
                return
            }
            // Try all date formats
            let dateString = currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines)
            var parsedDate: Date? = nil
            for formatter in dateFormatters {
                if let d = formatter.date(from: dateString) {
                    parsedDate = d
                    break
                }
            }
            if parsedDate == nil {
                print("[RSSParser] Skipped article in \(feedSourceName): missing or invalid date. Title: \(currentTitle), Date string: \(dateString)")
                insideItem = false
                return
            }
            let article = Article(id: currentID, title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines), link: URL(string: linkString)!, pubDate: parsedDate!, sourceName: feedSourceName)
            articles.append(article)
            insideItem = false
        }
    }
} 