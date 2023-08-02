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
					initialState: .preview,
					reducer: Reduce { state, action in
						if action == .isExpandedToggled {
							state.isExpanded.toggle()
						}

						return .none
					}
				)
			).background(Color.gray)
		}
	}
}
