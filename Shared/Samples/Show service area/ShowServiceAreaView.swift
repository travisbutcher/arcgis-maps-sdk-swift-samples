// Copyright 2024 Esri
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

import ArcGIS
import SwiftUI

struct ShowServiceAreaView: View {
    /// The error shown in the error alert.
    @State private var error: Error?
    
    /// The data model for the sample.
    @StateObject private var model = Model()
    
    /// Tracks whether to add facilities or barriers to map.
    @State private var selectedGraphicType: SelectedGraphicType = .facilities
    
    var body: some View {
        MapView(map: model.map, graphicsOverlays: [
            model.facilitiesGraphicsOverlay,
            model.barriersGraphicsOverlay,
            model.serviceAreaGraphicsOverlay
        ])
        .onSingleTapGesture { _, point in
            model.placeGraphicOnTapLocation(at: point, with: selectedGraphicType)
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Picker("Mode", selection: $selectedGraphicType) {
                    ForEach(SelectedGraphicType.allCases, id: \.self) {
                        Text($0.label)
                    }
                }
                .pickerStyle(.segmented)
                Spacer()
                Menu {
                    Slider(value: $model.secondTimeBreak, in: 1...15, step: 1) {
                        Text("Second: \(Int(model.secondTimeBreak))")
                    }
                    Slider(value: $model.firstTimeBreak, in: 1...15, step: 1) {
                        Text("First: \(Int(model.firstTimeBreak))")
                    }
                } label: {
                    Label("Time", systemImage: "gear")
                }
                Spacer()
                Button("Service Area") {
                    Task {
                        do {
                            try await model.showServiceArea()
                        } catch {
                            self.error = error
                        }
                    }
                }
                Spacer()
                Button("Clear", systemImage: "trash.fill") {
                    model.removeAllGraphics()
                }
            }
        }
        .errorAlert(presentingError: $error)
    }
}

private enum SelectedGraphicType: Equatable, CaseIterable {
    case facilities, barriers
    
    /// The string representation of the SelectedGraphic type.
    var label: String {
        switch self {
        case .barriers: "Barriers"
        case .facilities: "Facilities"
        }
    }
}

private extension ShowServiceAreaView {
//    @MainActor
    class Model: ObservableObject {
        /// Map with terrain style centered over San Diego.
        let map: Map = {
            let map = Map(basemapStyle: .arcGISTerrain)
            map.initialViewpoint = Viewpoint(
                center: Point(
                    x: -13041154,
                    y: 3858170,
                    spatialReference: .webMercator
                ),
                scale: 60000
            )
            return map
        }()
        
        private(set) var facilitiesGraphicsOverlay: GraphicsOverlay = {
            var facilitiesGraphicsOverlay = GraphicsOverlay()
            let facilitySymbol = PictureMarkerSymbol(image: UIImage(named: "PinBlueStar")!)
            // Offsets symbol in Y to align image properly.
            facilitySymbol.offsetY = 21
            // Assigns renderer on facilities graphics overlay using the picture marker symbol.
            facilitiesGraphicsOverlay.renderer = SimpleRenderer(symbol: facilitySymbol)
            return facilitiesGraphicsOverlay
        }()
        
        private(set) var barriersGraphicsOverlay: GraphicsOverlay = {
            var barriersGraphicsOverlay = GraphicsOverlay()
            let barrierSymbol = SimpleFillSymbol(style: .diagonalCross, color: .red, outline: nil)
            // Sets symbol on barrier graphics overlay using renderer.
            barriersGraphicsOverlay.renderer = SimpleRenderer(symbol: barrierSymbol)
            return barriersGraphicsOverlay
        }()
        
        private(set) var serviceAreaGraphicsOverlay = GraphicsOverlay()
        
        private var serviceAreaTask: ServiceAreaTask!
        
        private var serviceAreaParameters: ServiceAreaParameters!
        
        /// First time break property set in first slider.
        @Published var firstTimeBreak: Double = 3
        
        /// Second time break property set in second slider.
        @Published var secondTimeBreak: Double = 8
        
        /// Sets the service area task using the url and then sets the parameter to the default parameters returned
        /// from the service area task.
        private func setServiceArea() async throws {
            serviceAreaTask = ServiceAreaTask(url: .serviceArea)
            serviceAreaParameters = try await serviceAreaTask.makeDefaultParameters()
        }
        
        /// On user tapping on screen, depending on the selection type, it sets
        /// either the barrier or facilities overlays on the map at the tap point.
        /// - Parameters:
        ///   - point: The tap location.
        ///   - selection: The type of graphic to be added to the view.
        func placeGraphicOnTapLocation(at point: Point, with selection: SelectedGraphicType) {
            switch selection {
            case .facilities:
                let graphic = Graphic(geometry: point, symbol: nil)
                facilitiesGraphicsOverlay.addGraphic(graphic)
            case .barriers:
                let bufferedGeometry = GeometryEngine.buffer(around: point, distance: 500)
                let graphic = Graphic(geometry: bufferedGeometry, symbol: nil)
                barriersGraphicsOverlay.addGraphic(graphic)
            }
        }
        
        /// Gets the service area data and then renders the service area on the map.
        func showServiceArea() async throws {
            try await setServiceArea()
            serviceAreaGraphicsOverlay.removeAllGraphics()
            // In the facilities graphicsOverlays add a facility to the parameters for each one.
            let facilities = facilitiesGraphicsOverlay.graphics.map { ServiceAreaFacility(point: $0.geometry as! Point) }
            serviceAreaParameters.setFacilities(facilities)
            let barriers = barriersGraphicsOverlay.graphics.map { PolygonBarrier(polygon: $0.geometry as! Polygon) }
            serviceAreaParameters.setPolygonBarriers(barriers)
            serviceAreaParameters.removeAllDefaultImpedanceCutoffs()
            serviceAreaParameters.addDefaultImpedanceCutoffs([
                Double(firstTimeBreak),
                Double(secondTimeBreak)
            ])
            serviceAreaParameters.geometryAtOverlap = .dissolve
            try await renderServiceAreaPolygons()
        }
        
        private func renderServiceAreaPolygons() async throws {
            let result = try await serviceAreaTask.solveServiceArea(using: serviceAreaParameters)
            let polygons = result.resultPolygons(forFacilityAtIndex: 0)
            for index in polygons.indices {
                let polygon = polygons[index]
                let fillSymbol = makeServiceAreaSymbol(for: index)
                let graphic = Graphic(geometry: polygon.geometry, symbol: fillSymbol)
                serviceAreaGraphicsOverlay.addGraphic(graphic)
            }
        }
        
        /// Resets the graphics, removes the barriers, facilities and service area.
        func removeAllGraphics() {
            serviceAreaGraphicsOverlay.removeAllGraphics()
            facilitiesGraphicsOverlay.removeAllGraphics()
            barriersGraphicsOverlay.removeAllGraphics()
        }
        
        /// Sets the symbols drawn on that map for given selection.
        /// - Parameter index: Takes the index to decide how to render.
        /// - Returns: Returns the symbol.
        private func makeServiceAreaSymbol(for index: Int) -> Symbol {
            var fillSymbol: SimpleFillSymbol
            if index == 0 {
                let lineSymbol = SimpleLineSymbol(style: .solid, color: UIColor(red: 0.4, green: 0.4, blue: 0, alpha: 0.3), width: 2)
                fillSymbol = SimpleFillSymbol(style: .solid, color: UIColor(red: 0.8, green: 0.8, blue: 0, alpha: 0.3), outline: lineSymbol)
            } else {
                let lineSymbol = SimpleLineSymbol(style: .solid, color: UIColor(red: 0, green: 0.4, blue: 0, alpha: 0.3), width: 2)
                fillSymbol = SimpleFillSymbol(style: .solid, color: UIColor(red: 0, green: 0.8, blue: 0, alpha: 0.3), outline: lineSymbol)
            }
            return fillSymbol
        }
    }
}

private extension URL {
    static let serviceArea = URL(
        string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/NetworkAnalysis/SanDiego/NAServer/ServiceArea"
    )!
}

#Preview {
    ShowServiceAreaView()
}
