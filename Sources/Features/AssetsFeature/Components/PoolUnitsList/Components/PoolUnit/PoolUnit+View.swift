import FeaturePrelude

// MARK: - PoolUnit.View
extension PoolUnit {
	public struct ViewState: Equatable {
		let iconURL: URL?
		let name: String
		let resources: NonEmpty<IdentifiedArrayOf<PoolUnitResourceViewState>>
		let isSelected: Bool?
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

					HStack {
						PoolUnitResourcesView(resources: viewStore.resources)
							.padding(-.small2)

						if let isSelected = viewStore.isSelected {
							CheckmarkView(appearance: .dark, isChecked: isSelected)
						}
					}
					.onTapGesture { viewStore.send(.didTap) }
				}
				.padding(.medium1)
				.background(.app.white)
				.roundedCorners(radius: .small1)
				.tokenRowShadow()
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
			name: poolUnit.poolUnitResource.name ?? L10n.Account.PoolUnits.unknownPoolUnitName,
			resources: poolUnit.resourceViewStates,
			isSelected: isSelected
		)
	}
}

extension AccountPortfolio.PoolUnitResources.PoolUnit {
	var resourceViewStates: NonEmpty<IdentifiedArrayOf<PoolUnitResourceViewState>> {
		let xrdResourceViewState = poolResources.xrdResource.map {
			PoolUnitResourceViewState(
				thumbnail: .xrd,
				symbol: Constants.xrdTokenName,
				tokenAmount: redemptionValue(for: $0).format()
			)
		}

		return .init(
			rawValue: (xrdResourceViewState.map { [$0] } ?? [])
				+ poolResources.nonXrdResources.map {
					PoolUnitResourceViewState(
						thumbnail: .known($0.iconURL),
						symbol: $0.symbol ?? $0.name ?? L10n.Account.PoolUnits.unknownSymbolName,
						tokenAmount: redemptionValue(for: $0).format()
					)
				}
		)! // Safe to unwrap, guaranteed to not be empty
	}
}
