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
import ArcGIS

struct MeasureDistanceInSceneView: View {
    /// The view model for the sample.
    @StateObject private var model = Model()
    
    var body: some View {
        SceneView(scene: model.scene, analysisOverlays: [model.analysisOverlay])
            .alert(isPresented: $model.isShowingAlert, presentingError: model.error)
    }
}

private extension MeasureDistanceInSceneView {
    /// The view model for the sample.
    class Model: ObservableObject {
        /// A scene with an imagery basemap and centered on mountains in Chile.
        lazy var scene: ArcGIS.Scene = {
            // Creates a scene.
            let scene = Scene(basemapStyle: .arcGISTopographic)
            
            // Add elevation source to the base surface of the scene with the service URL.
            let elevationSource = ArcGISTiledElevationSource(url: .elevationService)
            scene.baseSurface.addElevationSource(elevationSource)
            
            // Create the building layer and add it to the scene.
            let buildingsLayer = ArcGISSceneLayer(url: .brestBuildingsService)
            // Offset the altitude to avoid clipping with the elevation source.
            buildingsLayer.altitudeOffset = 2
            scene.addOperationalLayer(buildingsLayer)
            
            // Set scene the viewpoint specified by the camera position.
            let lookAtPoint = Envelope(min: locationDistanceMeasurement.startLocation, max: locationDistanceMeasurement.endLocation).center
            let camera = Camera(lookingAt: lookAtPoint, distance: 200, heading: 0, pitch: 45, roll: 0)
            scene.initialViewpoint = Viewpoint(boundingGeometry: lookAtPoint, camera: camera)
            
            return scene
        }()
        
        /// An analysis overlay for location distance measurement.
        lazy var analysisOverlay = AnalysisOverlay(analyses: [locationDistanceMeasurement])
        
        /// The location distance measurement analysis.
        private let locationDistanceMeasurement: LocationDistanceMeasurement = {
            let startPoint = Point(x: -4.494677, y: 48.384472, z: 24.772694, spatialReference: .wgs84)
            let endPoint = Point(x: -4.495646, y: 48.384377, z: 58.501115, spatialReference: .wgs84)
            return LocationDistanceMeasurement(startLocation: startPoint, endLocation: endPoint)
        }()
        
        /// A Boolean value indicating whether to show an alert.
        @Published var isShowingAlert = false
        
        /// The error shown in the alert.
        @Published var error: Error? {
            didSet { isShowingAlert = error != nil }
        }
    }
}

private extension URL {
    /// A elevation image service URL.
    static var elevationService: URL {
        URL(string: "https://scene.arcgis.com/arcgis/rest/services/BREST_DTM_1M/ImageServer")!
    }
    
    /// A scene service URL for buildings in Brest, France.
    static var brestBuildingsService: URL {
        URL(string: "https://tiles.arcgis.com/tiles/P3ePLMYs2RVChkJx/arcgis/rest/services/Buildings_Brest/SceneServer/layers/0")!
    }
}
