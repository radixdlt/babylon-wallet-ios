import FeaturePrelude

// MARK: - Decommissioned.View
extension Decommissioned {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<Decommissioned>

		public init(store: StoreOf<Decommissioned>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				// TODO: implement
				VStack(alignment: .center) {
					VStack(alignment: .center, spacing: .small1) {
						Text("Preview of Wallet Has Ended") // FIXME: Strings
							.textStyle(.sectionHeader)
						Text("Uninstall this app and download the Radix Wallet app from App Store.") // FIXME: Strings
							.textStyle(.body1HighImportance)
							.multilineTextAlignment(.center)
					}
					.foregroundColor(.white)

					// So that the square root in background image is visible
					Spacer(minLength: .huge2)

					Button("Open AppStore") { // FIXME: Strings
						viewStore.send(.openAppStore)
					}
					.buttonStyle(.primaryRectangular)
				}
				.padding(.large1)
				.background(
					Image(asset: AssetResource.splash)
						.resizable()
						.scaledToFill()
				)
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - Decommissioned_Preview
struct Decommissioned_Preview: PreviewProvider {
	static var previews: some View {
		Decommissioned.View(
			store: .init(
				initialState: .previewValue,
				reducer: Decommissioned()
			)
		)
	}
}

extension Decommissioned.State {
	public static let previewValue = Self()
}
#endif
