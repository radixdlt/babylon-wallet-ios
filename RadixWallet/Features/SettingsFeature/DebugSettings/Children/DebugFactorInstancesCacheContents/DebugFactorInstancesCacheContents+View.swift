import SwiftUI

// MARK: - DebugFactorInstancesCacheContents.View
extension DebugFactorInstancesCacheContents {
    struct View: SwiftUI.View {
        let store: StoreOf<DebugFactorInstancesCacheContents>
        
        var body: some SwiftUI.View {
            WithPerceptionTracking {
                VStack(spacing: .small2) {
                    loadable(store.factorInstances) {
                        ProgressView()
                    } successContent: { factorInstances in
                        VStack {
//                            ForEach(factorInstances) { (factorSourceID, instancesForPresetsOfFactor) in
//                                Text("factorSourceID \(factorSourceID), #\(instancesForPresetsOfFactor.count)derivation presets")
//                            }
                            Text("Loaded 🐶🎉🐁 #\(factorInstances.count)")
                        }
                    }
                }
            }.task {
                store.send(.view(.task))
            }
        }
    }
}
