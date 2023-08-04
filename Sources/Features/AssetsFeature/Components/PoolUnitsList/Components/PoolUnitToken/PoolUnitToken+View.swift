import FeaturePrelude

// MARK: - PoolUnitToken.View
extension PoolUnitToken {
	public struct ViewState: Equatable {
		let iconURL: URL
		let name: String
		let components: NonEmpty<IdentifiedArrayOf<PoolUnitResourceView.ViewState>>
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<PoolUnitToken>

		public init(store: StoreOf<PoolUnitToken>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: \.viewState,
				send: PoolUnitToken.Action.view
			) { viewStore in
				Text("\(viewStore.name)")
			}
		}
	}
}

extension PoolUnitToken.State {
	var viewState: PoolUnitToken.ViewState {
		.init(
			iconURL: .init(string: "https://i.ibb.co/KG06168/Screenshot-2023-08-02-at-16-19-29.png")!,
			name: "Bytcoin",
			components: .init(
				rawValue: [
					.init(
						thumbnail: .xrd,
						symbol: "XRD",
						tokenAmount: "2.0129822"
					),
				]
			)!
		)
	}
}
