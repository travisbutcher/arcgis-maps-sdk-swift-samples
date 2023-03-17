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

extension ChangeMapViewBackgroundView {
    struct BackgroundGridSettingsView: View {
        /// The view model for the sample.
        @EnvironmentObject private var model: ChangeMapViewBackgroundView.Model
        
        var body: some View {
            List {
                Section("Background Grid") {
                    HStack {
                        ColorPicker(selection: $model.color) {
                            Text("Color")
                        }
                    }
                    HStack {
                        ColorPicker(selection: $model.lineColor) {
                            Text("Line Color")
                        }
                    }
                    VStack {
                        HStack {
                            Text("Line Width")
                            Spacer()
                            Text(model.lineWidth.formatted())
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $model.lineWidth, in: model.lineWidthRange, step: 1)
                    }
                    VStack {
                        HStack {
                            Text("Grid Size")
                            Spacer()
                            Text(model.size.formatted())
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Slider(value: $model.size, in: model.sizeRange, step: 1)
                    }
                }
            }
        }
    }
}
