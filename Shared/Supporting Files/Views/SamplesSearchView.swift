// Copyright 2023 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import SwiftUI

struct SamplesSearchView: View {
    /// The search query to highlight.
    private let query: String
    
    /// The search result to display in the various sections.
    private let searchResult: SearchResult
    
    /// A Boolean value indicating whether the search result contains any matches.
    private var hasMatches: Bool {
        !searchResult.nameMatches.isEmpty ||
        !searchResult.descriptionMatches.isEmpty ||
        !searchResult.tagMatches.isEmpty
    }
    
    /// Creates a sample search view.
    /// - Parameters:
    ///   - query: The search query in the search bar.
    init(query: String) {
        self.query = query
        self.searchResult = Self.searchSamples(with: query)
    }
    
    var body: some View {
        List {
            if !searchResult.nameMatches.isEmpty {
                Section("Name Results") {
                    ForEach(searchResult.nameMatches, id: \.name) { sample in
                        SampleLink(sample, textToBold: query)
                    }
                }
            }
            if !searchResult.descriptionMatches.isEmpty {
                Section("Description Results") {
                    ForEach(searchResult.descriptionMatches, id: \.name) { sample in
                        SampleLink(sample, textToBold: query)
                    }
                }
            }
            if !searchResult.tagMatches.isEmpty {
                Section("Tags Results") {
                    ForEach(searchResult.tagMatches, id: \.name) { sample in
                        SampleLink(sample, textToBold: query)
                    }
                }
            }
        }
        .overlay {
            // Once iOS 17.0 is the minimum supported platform,
            // this can be replaced with `ContentUnavailableView.search(text:)`.
            VStack {
                Text("No Results for \"\(query)\"")
                    .font(.title2)
                    .bold()
                Text("Check the spelling or try a new search.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .opacity(hasMatches ? 0 : 1)
        }
    }
}

// MARK: Search

private extension SamplesSearchView {
    /// A struct that contains various search results to be displayed in
    /// different sections in a list.
    struct SearchResult {
        /// The samples which name partially matches the search query.
        let nameMatches: [Sample]
        /// The samples which description partially matches the search query.
        let descriptionMatches: [Sample]
        /// The samples which one of the tags matches the search query.
        let tagMatches: [Sample]
    }
    
    /// Searches through the list of samples to find ones that match the query.
    /// - Parameters:
    ///   - query: The query to search with.
    private static func searchSamples(with query: String) -> SearchResult {
        let samples = SamplesApp.samples
        let nameMatches: [Sample]
        let descriptionMatches: [Sample]
        let tagMatches: [Sample]
        
        // The names of the samples already found in a previous section.
        var previousSearchResults: Set<String> = []
        
        // Partially match a query to a sample's name.
        nameMatches = samples.filter { $0.name.localizedCaseInsensitiveContains(query) }
        previousSearchResults.formUnion(nameMatches.map(\.name))
        
        // Partially match a query to a sample's description.
        descriptionMatches = samples.filter { $0.description.localizedCaseInsensitiveContains(query) }
            .filter { !previousSearchResults.contains($0.name) }
        previousSearchResults.formUnion(descriptionMatches.map(\.name))
        
        // Match a query to one of the sample's tags.
        tagMatches = samples.filter { sample in
            sample.tags.contains { tag in
                tag.localizedCaseInsensitiveCompare(query) == .orderedSame
            }
        }
        .filter { !previousSearchResults.contains($0.name) }
        
        return SearchResult(
            nameMatches: nameMatches,
            descriptionMatches: descriptionMatches,
            tagMatches: tagMatches
        )
    }
}
