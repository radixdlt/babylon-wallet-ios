import FeaturePrelude

extension AllowDenyAssets {
	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<AllowDenyAssets>

		@SwiftUI.State private var favoriteColor = 0

		init(store: StoreOf<AllowDenyAssets>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			VStack {
				Picker("What is your favorite color?", selection: $favoriteColor) {
					Text("Allow").tag(0)
					Text("Deny").tag(1)
				}
				.pickerStyle(.segmented)

				Spacer()
			}
			.navigationTitle("Allow/Deny Specific Assets")
			.defaultNavBarConfig()
			.background(.app.gray4)
		}
	}
}
