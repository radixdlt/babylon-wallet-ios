import FeaturePrelude

extension Decommissioned.State {
	var viewState: Decommissioned.ViewState {
		.init()
	}
}

// MARK: - Decommissioned.View
extension Decommissioned {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<Decommissioned>

		public init(store: StoreOf<Decommissioned>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				VStack(alignment: .center) {
					VStack(alignment: .center, spacing: .small1) {
						Text("Preview of wallet has ended")
							.textStyle(.sectionHeader)
						Text("Uninstall this app and download the Radix Wallet app from App Store.")
							.textStyle(.body1HighImportance)
					}
					.foregroundColor(.white)

					// So that the square root in background image is visible
					Spacer(minLength: .huge2)

					Button("Open AppStore") {
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
