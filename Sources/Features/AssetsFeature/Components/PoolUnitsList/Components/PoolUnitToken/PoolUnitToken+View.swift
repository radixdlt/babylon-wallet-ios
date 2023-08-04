import FeaturePrelude

// MARK: - LPToken.View
extension LPToken {
	public struct ViewState: Equatable {
		let iconURL: URL
		let name: String
		let resources: NonEmpty<IdentifiedArrayOf<PoolUnitResourceView.ViewState>>
	}

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
				VStack {
					X(viewState: .init(iconURL: viewStore.iconURL, name: viewStore.name))

					VStack(spacing: 1) {
						ForEach(
							viewStore.resources,
							content: PoolUnitResourceView.init
						)
						.padding(.medium3)
						.background(.app.white)
					}
					.background(.app.gray4)
					.overlay(
						RoundedRectangle(cornerRadius: .small1)
							.stroke(.app.gray4, lineWidth: 1)
					)
					.padding(.small2 * -1)
				}
				.padding(.medium1)
				.background(.app.white)
				.roundedCorners(radius: .small1)
				.tokenRowShadow()
			}
		}
	}
}

extension LPToken.State {
	var viewState: LPToken.ViewState {
		.init(
			iconURL: .init(string: "https://i.ibb.co/KG06168/Screenshot-2023-08-02-at-16-19-29.png")!,
			name: "Bytcoin",
			resources: .init(
				rawValue: [
					.init(
						thumbnail: .xrd,
						symbol: "XRD",
						tokenAmount: "2.0129822"
					),
					.init(
						thumbnail: .known(.init(string: "https://i.ibb.co/KG06168/Screenshot-2023-08-02-at-16-19-29.png")!),
						symbol: "WTF",
						tokenAmount: "32.6129822"
					),
				]
			)!
		)
	}
}
