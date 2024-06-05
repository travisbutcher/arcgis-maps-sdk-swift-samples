//
//  ApplyMosaicRuleToRastersView.swift
//  Samples
//
//  Created by Christopher Webb on 6/5/24.
//  Copyright © 2024 Esri. All rights reserved.
//

import ArcGIS
import SwiftUI

struct ApplyMosaicRuleToRastersView: View {
    /// The error shown in the error alert.
    @State private var error: Error?
    
    /// A Boolean value indicating whether a download operation is in progress.
    @State private var isLoading = false
    
    @State private var showingAlert = false
    
    /// The current viewpoint of the map view.
    @State private var viewpoint: Viewpoint?
    
    @State private var map: Map = {
        let map = Map(basemapStyle: .arcGISDarkGrayBase)
        // Creates an initial Viewpoint with a coordinate point centered on San Franscisco's Golden Gate Bridge.
        map.initialViewpoint = Viewpoint(
            center: Point(x: -13637000, y: 4550000, spatialReference: .webMercator),
            scale: 100_000
        )
        return map
    }()
    
    @State private var imageServiceRaster = {
        let imageServiceRaster = ImageServiceRaster(url: .imageServiceURL)
        imageServiceRaster.mosaicRule = MosaicRule()
        return imageServiceRaster
    }()
    
    @State private var mosaicRulePairs: [String: MosaicRule] = {
        // A default mosaic rule object, with mosaic method as none.
        let noneRule = MosaicRule()
        noneRule.mosaicMethod = .nadir
        
        // A mosaic rule object with northwest method.
        let northWestRule = MosaicRule()
        northWestRule.mosaicMethod = .northwest
        northWestRule.mosaicOperation = .first
        
        // A mosaic rule object with center method and blend operation.
        let centerRule = MosaicRule()
        centerRule.mosaicMethod = .center
        centerRule.mosaicOperation = .blend
        
        // A mosaic rule object with byAttribute method and sort on "OBJECTID" field of the service.
        let byAttributeRule = MosaicRule()
        byAttributeRule.mosaicMethod = .attribute
        byAttributeRule.sortField = "OBJECTID"
        
        // A mosaic rule object with lockRaster method and locks 3 image rasters.
        let lockRasterRule = MosaicRule()
        lockRasterRule.mosaicMethod = .lockRaster
        lockRasterRule.addLockRasterIDs([1, 7, 12])
        
        
        return ["None": noneRule,
                "NorthWest": northWestRule,
                "Center": centerRule,
                "ByAttribute": byAttributeRule,
                "LockRaster": lockRasterRule]
    }()
    
    init() {
        let rasterLayer = RasterLayer(raster: imageServiceRaster)
        map.addOperationalLayer(rasterLayer)
    }
    
    var body: some View {
        NavigationStack {
            MapViewReader { mapProxy in
                MapView(map: map, viewpoint: viewpoint)
                    .onViewpointChanged(kind: .centerAndScale) { viewpoint = $0 }
                    .overlay(alignment: .center) {
                        if isLoading {
                            ProgressView("Loading...")
                                .padding()
                                .background(.ultraThickMaterial)
                                .cornerRadius(10)
                                .shadow(radius: 50)
                        }
                    }
                    .task {
                        guard let rasterLayer = map.operationalLayers.first as? RasterLayer else {
                            return
                        }
                        do {
                            isLoading = true
                            defer { isLoading = false }
                            // Downloads raster from online service.
                            try await rasterLayer.load()
                        } catch {
                            // Presents an error message if the raster fails to load.
                            self.error = error
                        }
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .primaryAction) {
                            Button("Rules") {
                                showingAlert = true
                                print("About tapped!")
                            }
                            .actionSheet(isPresented: $showingAlert) {
                                ActionSheet(title: Text("Title"), message: Text("Choose one of this three:"), buttons: [
                                    .default(Text("NorthWest")) {
                                        Task {
                                            await self.mosiacRuleSelect(at: "NorthWest", using: mapProxy)
                                        }
                                    },
                                        .default(Text("Center")) {
                                            Task {
                                                await self.mosiacRuleSelect(at: "Center", using: mapProxy)
                                            }
                                        },
                                    .default(Text("ByAttribute")) {
                                        Task {
                                            await self.mosiacRuleSelect(at: "ByAttribute", using: mapProxy)
                                        }
                                    },
                                    .default(Text("LockRaster")) {
                                        Task {
                                            await self.mosiacRuleSelect(at: "LockRaster", using: mapProxy)
                                        }
                                    },
                                    .default(Text("None")) {
                                        Task {
                                            await self.mosiacRuleSelect(at: "None", using: mapProxy)
                                        }
                                    }
                                ])
                            }
                        }
                    }
            }
        }
    }
    
    private func mosiacRuleSelect(at selection: String, using proxy: MapViewProxy) async -> Void {
        guard let rasterLayer = map.operationalLayers.first as? RasterLayer else {
            return
        }
        imageServiceRaster.mosaicRule = mosaicRulePairs[selection]
        if let center = self.imageServiceRaster.serviceInfo?.fullExtent?.center {
            await proxy.setViewpoint(Viewpoint(center: center, scale: 250000.0))
        }
    }
}

private extension URL {
    static let imageServiceURL = URL(string: "https://sampleserver7.arcgisonline.com/server/rest/services/amberg_germany/ImageServer")!
}

#Preview {
    ApplyMosaicRuleToRastersView()
}
