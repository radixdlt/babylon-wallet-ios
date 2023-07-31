import AssetsFeature
import ComposableArchitecture
import SwiftUI

// MARK: - AssetsFeaturePreviewApp
@main
struct AssetsFeaturePreviewApp: App {
	var body: some Scene {
		WindowGroup {
			PoolUnitsList.View(
				store: .init(
					initialState: .init(),
					reducer: EmptyReducer()
				)
			)
		}
	}
}
