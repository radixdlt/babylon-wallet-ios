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
	var viewState: PoolUnit.ViewState {
		.init(
			iconURL: poolUnit.poolUnitResource.iconURL,
			name: poolUnit.poolUnitResource.name ?? "Unknown", // FIXME: strings
			resources: poolUnit.resourceViewStates
		)
	}
}

extension AccountPortfolio.PoolUnitResources.PoolUnit {
	var resourceViewStates: NonEmpty<IdentifiedArrayOf<PoolUnitResourceViewState>> {
		let xrdResourceViewState = poolResources.xrdResource.map {
			PoolUnitResourceViewState(
				thumbnail: .xrd,
				symbol: "XRD",
				tokenAmount: redemptionValue(for: $0).format()
			)
		}

		return .init(
			rawValue: xrdResourceViewState.map { [$0] } ?? []
				+ poolResources.nonXrdResources.map {
					PoolUnitResourceViewState(
						thumbnail: .known($0.iconURL),
						symbol: $0.symbol ?? $0.name ?? "Unknown", // FIXME: strings
						tokenAmount: redemptionValue(for: $0).format()
					)
				}
		)! // Safe to unwrap, guaranteed to not be empty
	}
}
