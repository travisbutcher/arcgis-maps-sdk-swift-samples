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

struct SetSurfaceNavigationConstraintView: View {
    /// The Webscene with a portal item.
    @State private var scene: ArcGIS.Scene = {
        // Creates the portal item using the id of the Webscene in the ArcGIS portal.
        let portalItem = PortalItem(
            portal: .arcGISOnline(connection: .anonymous),
            id: PortalItem.ID("91a4fafd747a47c7bab7797066cb9272")!
        )
        // Creates the scene using the portal item.
        let scene = Scene(item: portalItem)
        // Sets the navigation constraint on the scene's base surface to unconstrained which allowd the camera pass above and below the elevation surface.
        scene.baseSurface.navigationConstraint = .unconstrained
        return scene
    }()

    var body: some View {
        // Displays the Webscene in the SceneView
        SceneView(scene: scene)
    }
}

#Preview {
    SetSurfaceNavigationConstraintView()
}
