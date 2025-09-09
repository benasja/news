import Foundation

struct Article: Identifiable, Codable {
    let id: UUID
    let title: String
    let link: URL
    let pubDate: Date
    let sourceName: String
} 