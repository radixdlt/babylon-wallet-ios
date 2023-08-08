import FeaturePrelude

// MARK: - PoolUnit.View
extension PoolUnit {
	public struct ViewState: Equatable {
		let iconURL: URL?
		let name: String
		let resources: NonEmpty<IdentifiedArrayOf<PoolUnitResourceViewState>>
	}

	public struct View: SwiftUI.View {
		private let store: StoreOf<PoolUnit>

		public init(store: StoreOf<PoolUnit>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: \.viewState,
				send: PoolUnit.Action.view
			) { viewStore in
				VStack(spacing: .large2) {
					PoolUnitHeaderView(viewState: .init(iconURL: viewStore.iconURL)) {
						Text(viewStore.name)
							.foregroundColor(.app.gray1)
							.textStyle(.secondaryHeader)
					}
					.padding(-.small3)

					PoolUnitResourcesView(resources: viewStore.resources)
						.padding(-.small2)
				}
				.padding(.medium1)
				.background(.app.white)
				.roundedCorners(radius: .small1)
				.tokenRowShadow()
				.onTapGesture {
					viewStore.send(.didTap)
				}
			}
			.sheet(
				store: store.scope(
					state: \.$destination,
					action: (/Action.child .. PoolUnit.ChildAction.destination).embed
				),
				state: /Destinations.State.details,
				action: Destinations.Action.details,
				content: PoolUnitDetails.View.init
			)
		}
	}
}

extension PoolUnit.State {
	// FIXME: Rewire to real State
	var viewState: PoolUnit.ViewState {
		.init(
			iconURL: .init(string: "https://i.ibb.co/KG06168/Screenshot-2023-08-02-at-16-19-29.png")!,
			name: "Some LP Token",
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
