import Foundation

struct FeedSource: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var url: String
    
    init(id: UUID = UUID(), name: String, url: String) {
        self.id = id
        self.name = name
        self.url = url
    }
} 
