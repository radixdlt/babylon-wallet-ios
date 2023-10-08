import FeaturePrelude

// MARK: - PoolUnit.View
extension PoolUnit {
	public struct ViewState: Equatable {
		let iconURL: URL?
		let name: String
		let resources: Loadable<NonEmpty<IdentifiedArrayOf<PoolUnitResourceViewState>>>
		let isSelected: Bool?
	}

	public struct View: SwiftUI.View {
		private let store: StoreOf<PoolUnit>
		@Environment(\.refresh) var refresh

		public init(store: StoreOf<PoolUnit>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: \.viewState,
				send: PoolUnit.Action.view
			) { viewStore in
				Section {
					VStack(spacing: .large2) {
						PoolUnitHeaderView(viewState: .init(iconURL: viewStore.iconURL)) {
							Text(viewStore.name)
								.foregroundColor(.app.gray1)
								.textStyle(.secondaryHeader)
						}
						.padding(-.small3)
						if refresh != nil {
							Text("refreshing")
						}
						loadable(viewStore.resources) { resources in
							HStack {
								PoolUnitResourcesView(resources: resources)
									.padding(-.small2)

								if let isSelected = viewStore.isSelected {
									CheckmarkView(appearance: .dark, isChecked: isSelected)
								}
							}
							.onTapGesture { viewStore.send(.didTap) }
						}
					}
					.padding(.medium1)
					.background(.app.white)
					.rowStyle()
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
			iconURL: poolUnit.resource.metadata.iconURL,
			name: poolUnit.resource.metadata.name ?? L10n.Account.PoolUnits.unknownPoolUnitName,
			resources: resourceDetails.map { details in
				PoolUnitResourceViewState.viewStates(poolUnit: poolUnit, resourcesDetails: details)
			},
			isSelected: isSelected
		)
	}
}

extension PoolUnitResourceViewState {
	static func viewStates(
		poolUnit: OnLedgerEntity.Account.PoolUnit,
		resourcesDetails: PoolUnit.State.ResourceDetails
	) -> NonEmpty<IdentifiedArrayOf<PoolUnitResourceViewState>> {
		fatalError()
//		func redemptionValue(for resource: OnLedgerEntity.OwnedFungibleResource, resourceDetails: OnLedgerEntity.Resource?) -> String {
//			guard let resourceDetails else {
//				assertionFailure("Not all resources were loaded")
//				return ""
//			}
//			guard let poolUnitTotalSupply = resourcesDetails.poolUnitResource.totalSupply else {
//				loggerGlobal.error("Missing total supply for \(resource.resourceAddress.address)")
//				return "Missing Total supply - could not calculate redemption value" // FIXME: Strings
//			}
		//            let redemptionValue = poolUnit.resource.amount * (resource.amount / poolUnitTotalSupply)
//			let decimalPlaces = resourceDetails.divisibility.map(UInt.init) ?? RETDecimal.maxDivisibility
//			let roundedRedemptionValue = redemptionValue.rounded(decimalPlaces: decimalPlaces)
//
//			return roundedRedemptionValue.formatted()
//		}
//
//		let xrdResourceViewState = poolUnit.poolResources.xrdResource.map {
//			PoolUnitResourceViewState(
//				thumbnail: .xrd,
//				symbol: Constants.xrdTokenName,
//				tokenAmount: redemptionValue(for: $0, resourceDetails: resourcesDetails.xrdResource)
//			)
//		}
//
//		return .init(
//			rawValue: (xrdResourceViewState.map { [$0] } ?? [])
//				+ poolUnit.poolResources.nonXrdResources.map { resource in
//					PoolUnitResourceViewState(
//						thumbnail: .known(resource.metadata.iconURL),
//						symbol: resource.metadata.symbol ?? resource.metadata.name ?? L10n.Account.PoolUnits.unknownSymbolName,
//						tokenAmount: redemptionValue(
//							for: resource,
//							resourceDetails: resourcesDetails.nonXrdResources.first { $0.resourceAddress == resource.resourceAddress }
//						)
//					)
//				}
//		)! // Safe to unwrap, guaranteed to not be empty
	}
}
