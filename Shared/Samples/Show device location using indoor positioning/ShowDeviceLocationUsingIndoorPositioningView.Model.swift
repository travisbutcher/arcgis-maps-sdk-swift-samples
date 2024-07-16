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
import CoreLocation
import SwiftUI

extension ShowDeviceLocationUsingIndoorPositioningView {
    @MainActor
    class Model: ObservableObject {
        /// A indoors location data source based on sensor data, including but not
        /// limited to radio, GPS, motion sensors.
        @Published var indoorsLocationDataSource: IndoorsLocationDataSource?
        @Published var currentFloor: Int = 0
        
        @Published var sensorCount: Int!
        
        @Published var satelliteCount: Int!
        
        @Published var horizontalAccuracy: Double!
        
        /// The map's location display.
        @Published var locationDisplay = LocationDisplay()
        
        @Published var enveloper: Envelope?
        
        @Published var source: String = ""
        
        @Published var levelID: UUID?
        
        /// The measurement formatter for sensor accuracy.
        let measurementFormatter: MeasurementFormatter = {
            let formatter = MeasurementFormatter()
            formatter.unitStyle = .short
            formatter.unitOptions = .providedUnit
            return formatter
        }()
        
        func setIndoorDatasource(map: Map) async throws {
            locationDisplay.autoPanMode = .navigation
            try await map.indoorPositioningDefinition?.load()
            indoorsLocationDataSource = IndoorsLocationDataSource(definition: map.indoorPositioningDefinition!)
            locationDisplay.dataSource = indoorsLocationDataSource!
            try await startLocationDisplay()
            try await updateLocation(map: map)
        }
        
        func updateLocation(map: Map) async throws {
            for try await location in locationDisplay.dataSource.locations {
                if let floorLevel = location.additionalSourceProperties[.floor] as? Int {
                    currentFloor = floorLevel
                    try await displayFeatures(map: map, onFloor: currentFloor + 1)
                }
                
                if let floorLevelID = location.additionalSourceProperties[.floorLevelID] as? UUID {
                    levelID = floorLevelID
                }
                source = location.additionalSourceProperties[.positionSource] as? String ?? "NA"
                switch source {
                case "GNSS":
                    satelliteCount = location.additionalSourceProperties[.satelliteCount] as? Int ?? 0
                default:
                    sensorCount = location.additionalSourceProperties[.transmitterCount] as? Int ?? 0
                }
                horizontalAccuracy = location.horizontalAccuracy
            }
        }
        
        /// Starts the location display to show user's location on the map.
        func startLocationDisplay() async throws {
            // Request location permission if it has not yet been determined.
            let locationManager = CLLocationManager()
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            }
            // Start the location display to zoom to the user's current location.
            try await locationDisplay.dataSource.start()
        }
        
        /// Display features on a certain floor level using definition expression.
        /// - Parameter floor: The floor level of the features to be displayed.
        func displayFeatures(map: Map, onFloor floor: Int) async throws {
            for layer in map.operationalLayers {
                if layer.name == "Details" || layer.name == "Units" || layer.name == "Levels" {
                    if let featureLayer = layer as? FeatureLayer {
                        featureLayer.definitionExpression = "VERTICAL_ORDER = \(floor)"
                    }
                }
            }
        }
    }
}
