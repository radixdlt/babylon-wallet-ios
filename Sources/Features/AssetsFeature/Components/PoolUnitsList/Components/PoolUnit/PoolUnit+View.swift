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
				.task { @MainActor in
					await viewStore.send(.task).finish()
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
			iconURL: poolUnit.poolUnitResource.metadata.iconURL,
			name: poolUnit.poolUnitResource.metadata.name ?? L10n.Account.PoolUnits.unknownPoolUnitName,
			resources: PoolUnitResourceViewState.resourcesViewState(poolUnit: poolUnit, loadedPoolResources: loadedPoolResources),
			isSelected: isSelected
		)
	}
}

extension PoolUnitResourceViewState {
	static func resourcesViewState(
		poolUnit: AccountPortfolio.PoolUnitResources.PoolUnit,
		loadedPoolResources: Loadable<[OnLedgerEntity.Resource]>
	) -> NonEmpty<IdentifiedArrayOf<PoolUnitResourceViewState>> {
		func redemptionValue(for resource: AccountPortfolio.FungibleResource) -> Loadable<String> {
			loadedPoolResources.map { loadedPoolResources in
				let poolUnitResource = loadedPoolResources.first { $0.id == poolUnit.poolUnitResource.id }
				let loadedResource = loadedPoolResources.first { $0.id == resource.id }
				guard let poolUnitResource, let loadedResource else {
					assertionFailure("Not all resources were loaded")
					return ""
				}

				let poolUnitTotalSupply = poolUnitResource.totalSupply ?? .one
				let unroundedRedemptionValue = poolUnit.poolUnitResource.amount * resource.amount / poolUnitTotalSupply
				return unroundedRedemptionValue.format(divisibility: loadedResource.divisibility)
			}
		}

		let xrdResourceViewState = poolUnit.poolResources.xrdResource.map {
			PoolUnitResourceViewState(
				thumbnail: .xrd,
				symbol: Constants.xrdTokenName,
				tokenAmount: redemptionValue(for: $0)
			)
		}

		return .init(
			rawValue: (xrdResourceViewState.map { [$0] } ?? [])
				+ poolUnit.poolResources.nonXrdResources.map {
					PoolUnitResourceViewState(
						thumbnail: .known($0.metadata.iconURL),
						symbol: $0.metadata.symbol ?? $0.metadata.name ?? L10n.Account.PoolUnits.unknownSymbolName,
						tokenAmount: redemptionValue(for: $0)
					)
				}
		)! // Safe to unwrap, guaranteed to not be empty
	}
}
