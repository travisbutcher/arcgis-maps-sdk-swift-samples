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

struct CategoriesView: View {
    /// The visibility of the leading columns in the navigation split view.
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
    /// The selected category loaded from user defaults.
    @AppStorage("selectedCategory") private var selectedCategory: String?
    
    /// A Boolean value indicating whether the navigation destination is showing.
    @State private var destinationIsPresented = false
    
    /// The list of categories.
    private let categories: [String] = {
        var categories = ["All", "Favorites"]
        let sampleCategories = Set(SamplesApp.samples.map(\.category))
        categories.append(contentsOf: sampleCategories.sorted())
        return categories
    }()
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(), GridItem()]) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        selectedCategory = category
                        columnVisibility = .doubleColumn
                    } label: {
                        CategoryTile(name: category)
                    }
                    .buttonStyle(.plain)
                    .contentShape(RoundedRectangle(cornerRadius: 15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(
                                category == selectedCategory ? Color.accentColor : Color.clear,
                                lineWidth: 5
                            )
                    )
                }
            }
            .padding()
        }
        .navigationDestination(isPresented: $destinationIsPresented) {
            Group {
                switch selectedCategory {
                case "All":
                    AllSamplesView()
                case "Favorites":
                    FavoritesView()
                default:
                    List(SamplesApp.samples.filter { $0.category == selectedCategory }, id: \.name) {
                        SampleLink($0)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(selectedCategory ?? "")
        }
        .onChange(of: destinationIsPresented) { _ in
            // Resets the selection when the navigation destination is no longer presented.
            guard !destinationIsPresented else { return }
            selectedCategory = nil
        }
        .onChange(of: selectedCategory) { newSelection in
            destinationIsPresented = newSelection != nil
        }
        .onAppear {
            // Presents the destination if there is a category loaded from the user defaults.
            destinationIsPresented = selectedCategory != nil
        }
    }
}

private extension CategoriesView {
    struct CategoryTile: View {
        /// The name of the category.
        let name: String
        
        var body: some View {
            Image("\(name.replacingOccurrences(of: " ", with: "-"))-bg")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .overlay {
                    Color(red: 0.24, green: 0.24, blue: 0.26, opacity: 0.6)
                    Image("\(name.replacingOccurrences(of: " ", with: "-"))-icon")
                        .resizable()
                        .colorInvert()
                        .padding(10)
                        .frame(width: 50, height: 50)
                        .background(.black.opacity(0.75))
                        .clipShape(Circle())
                    Text(name)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .offset(y: 45)
                }
                .clipShape(RoundedRectangle(cornerRadius: 15))
        }
    }
    
    struct AllSamplesView: View {
        /// The query in the search bar
        @State private var query = ""
        
        var body: some View {
            Group {
                if !query.isEmpty {
                    SamplesSearchView(query: query)
                } else {
                    List(SamplesApp.samples, id: \.name) { sample in
                        SampleLink(sample, textToBold: query)
                    }
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
        }
    }
}
