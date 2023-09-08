import FeaturePrelude

extension Decommissioned.State {
	var viewState: Decomissioned.ViewState {
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
				Text("The Preview of Radix wallet has ended. Uninstall this app and download the Radix Wallet app from App Store.")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
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
