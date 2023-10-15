import AssetsFeature
import ComposableArchitecture
import SwiftUI

// MARK: - AssetsFeaturePreviewApp
@main
struct AssetsFeaturePreviewApp: App {
	var body: some Scene {
		WindowGroup {
			// FIXME: Does not work for now ☹️
			AssetsView.View(
				store: .init(
					initialState: .init(account: .previewValue0),
					reducer: AssetsView.init
				)
			)
		}
	}
}
