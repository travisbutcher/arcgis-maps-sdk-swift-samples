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

struct SearchResultView: View {
    /// All samples retrieved from the Samples directory.
    let samples: [Sample]
    
    /// The search query in the search bar.
    let query: String
    
    /// The search result to display in the various sections.
    @State private var searchResult = SearchResult(nameMatches: [], descriptionMatches: [], tagMatches: [])
    
    var body: some View {
        List {
            if !searchResult.nameMatches.isEmpty {
                Section(header: Text("Name Results")) {
                    ForEach(searchResult.nameMatches, id: \.name) { sample in
                        SampleRow(sample: sample, boldedText: query)
                    }
                }
            }
            if !searchResult.descriptionMatches.isEmpty {
                Section(header: Text("Description Results")) {
                    ForEach(searchResult.descriptionMatches, id: \.name) { sample in
                        SampleRow(sample: sample, boldedText: query)
                    }
                }
            }
            if !searchResult.tagMatches.isEmpty {
                Section(header: Text("Tags Results")) {
                    ForEach(searchResult.tagMatches, id: \.name) { sample in
                        SampleRow(sample: sample, boldedText: query)
                    }
                }
            }
        }
        .onChange(of: query) { newQuery in
            searchResult = searchSamples(in: samples, with: newQuery)
        }
        .onAppear {
            searchResult = searchSamples(in: samples, with: query)
        }
    }
}

// MARK: Search

private extension SearchResultView {
    /// A struct that contains various search results to be displayed in
    /// different sections in a list.
    struct SearchResult {
        /// The samples which name partially matches the search query.
        let nameMatches: [Sample]
        /// The samples which description partially matches the search query.
        let descriptionMatches: [Sample]
        /// The samples which one of the tags matches the search query.
        let tagMatches: [Sample]
        
        /// A Boolean value indicating whether all the matches are empty.
        var isEmpty: Bool {
            nameMatches.isEmpty && descriptionMatches.isEmpty && tagMatches.isEmpty
        }
    }
    
    /// Searches through a list of samples to find ones that match the query.
    /// - Parameters:
    ///   - samples: The samples to search through.
    ///   - query: The query to search with.
    private func searchSamples(in samples: [Sample], with query: String) -> SearchResult {
        let nameMatches: [Sample]
        let descriptionMatches: [Sample]
        let tagMatches: [Sample]
        
        if query.isEmpty {
            // Show all samples in the name section when query is empty.
            nameMatches = samples
            descriptionMatches = []
            tagMatches = []
        } else {
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
        }
        
        return SearchResult(
            nameMatches: nameMatches,
            descriptionMatches: descriptionMatches,
            tagMatches: tagMatches
        )
    }
}
