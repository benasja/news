import SwiftUI

struct SourcesStatusView: View {
    @State private var failedSources: [String: String] = RSSParser.failedSources
    var body: some View {
        NavigationView {
            List {
                if failedSources.isEmpty {
                    Text("All sources loaded successfully.")
                        .foregroundColor(.green)
                } else {
                    ForEach(failedSources.sorted(by: { $0.key < $1.key }), id: \ .key) { key, value in
                        VStack(alignment: .leading) {
                            Text(key)
                                .font(.headline)
                            Text(value)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Sources Status")
            .onAppear {
                failedSources = RSSParser.failedSources
            }
        }
    }
} 