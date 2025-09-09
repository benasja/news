import SwiftUI

struct EditSourcesView: View {
    @Binding var sources: [FeedSource]
    @State private var newName: String = ""
    @State private var newURL: String = ""
    @State private var editingSource: FeedSource? = nil
    @State private var editedName: String = ""
    @State private var editedURL: String = ""
    @FocusState private var urlFieldFocused: Bool
    var onSourcesChanged: (() -> Void)? = nil
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Current Sources")) {
                    List {
                        ForEach(sources) { source in
                            Button(action: {
                                editingSource = source
                                editedName = source.name
                                editedURL = source.url
                            }) {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(source.name).font(.headline)
                                        Spacer()
                                        if let error = RSSParser.failedSources[source.name] {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(.red)
                                                .help(error)
                                        }
                                    }
                                    Text(source.url).font(.caption).foregroundColor(.secondary)
                                    if let error = RSSParser.failedSources[source.name] {
                                        Text(error)
                                            .font(.caption2)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        .onDelete { offsets in
                            sources.remove(atOffsets: offsets)
                            onSourcesChanged?()
                        }
                    }
                }
                Section(header: Text("Add New Source")) {
                    TextField("Source Name", text: $newName)
                    TextField("Source URL", text: $newURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .focused($urlFieldFocused)
                    Button("Add Source") {
                        guard !newName.isEmpty, let url = URL(string: newURL), url.scheme?.hasPrefix("http") == true else { return }
                        sources.append(FeedSource(name: newName, url: newURL))
                        newName = ""
                        newURL = ""
                        urlFieldFocused = false
                        onSourcesChanged?()
                    }
                    .disabled(newName.isEmpty || newURL.isEmpty)
                }
            }
            .navigationTitle("Edit Sources")
            .sheet(item: $editingSource) { source in
                NavigationView {
                    Form {
                        Section(header: Text("Edit Source")) {
                            TextField("Source Name", text: $editedName)
                            TextField("Source URL", text: $editedURL)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                        }
                        Button("Save Changes") {
                            if let idx = sources.firstIndex(where: { $0.id == source.id }) {
                                sources[idx].name = editedName
                                sources[idx].url = editedURL
                                onSourcesChanged?()
                            }
                            editingSource = nil
                        }
                        .disabled(editedName.isEmpty || editedURL.isEmpty)
                        Button("Cancel", role: .cancel) {
                            editingSource = nil
                        }
                    }
                    .navigationTitle("Edit Source")
                }
            }
        }
    }
} 