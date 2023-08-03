import AssetsFeature
import ComposableArchitecture
import SwiftUI

// MARK: - AssetsFeaturePreviewApp
@main
struct AssetsFeaturePreviewApp: App {
	var body: some Scene {
		WindowGroup {
			AssetsView.View(
				store: .init(
					initialState: .init(account: .previewValue0),
					reducer: AssetsView.init
				)
			)
		}
	}
}
