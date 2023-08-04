import FeaturePrelude

// MARK: - LPToken.View
extension LPToken {
	public struct ViewState: Equatable {
		let iconURL: URL
		let name: String
		let components: NonEmpty<IdentifiedArrayOf<PoolUnitResourceView.ViewState>>
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<LPToken>

		public init(store: StoreOf<LPToken>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: \.viewState,
				send: LPToken.Action.view
			) { viewStore in
				Text("\(viewStore.name)")
			}
		}
	}
}

extension LPToken.State {
	var viewState: LPToken.ViewState {
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
