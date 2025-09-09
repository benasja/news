import SwiftUI

struct EditSportsSourcesView: View {
    @ObservedObject var viewModel: SportsViewModel
    @State private var newName: String = ""
    @State private var newURL: String = ""
    @FocusState private var urlFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Current Sources")) {
                    List {
                        ForEach(viewModel.sources) { source in
                            VStack(alignment: .leading) {
                                Text(source.name).font(.headline)
                                Text(source.url).font(.caption).foregroundColor(.secondary)
                            }
                        }
                        .onDelete(perform: viewModel.removeSource)
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
                        viewModel.addSource(name: newName, url: newURL)
                        newName = ""
                        newURL = ""
                        urlFieldFocused = false
                    }
                    .disabled(newName.isEmpty || newURL.isEmpty)
                }
            }
            .navigationTitle("Edit Sports Sources")
        }
    }
} 