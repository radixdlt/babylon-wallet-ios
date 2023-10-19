import ComposableArchitecture
import SwiftUI

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
		resourcesDetails: OnLedgerEntitiesClient.OwnedResourcePoolDetails
	) -> NonEmpty<IdentifiedArrayOf<PoolUnitResourceViewState>> {
		func redemptionValue(for resourceDetails: OnLedgerEntitiesClient.ResourceWithVaultAmount) -> String {
			guard let poolUnitTotalSupply = resourcesDetails.poolUnitResource.resource.totalSupply else {
				loggerGlobal.error("Missing total supply for \(resourcesDetails.poolUnitResource.resource.totalSupply)")
				return "Missing Total supply - could not calculate redemption value" // FIXME: Strings
			}
			let redemptionValue = poolUnit.resource.amount * (resourceDetails.amount / poolUnitTotalSupply)
			let decimalPlaces = resourceDetails.resource.divisibility.map(UInt.init) ?? RETDecimal.maxDivisibility
			let roundedRedemptionValue = redemptionValue.rounded(decimalPlaces: decimalPlaces)

			return roundedRedemptionValue.formatted()
		}

		let xrdResourceViewState = resourcesDetails.xrdResource.map {
			PoolUnitResourceViewState(
				thumbnail: .xrd,
				symbol: Constants.xrdTokenName,
				tokenAmount: redemptionValue(for: $0)
			)
		}

		return .init(
			rawValue: (xrdResourceViewState.map { [$0] } ?? [])
				+ resourcesDetails.nonXrdResources.map { resourceDetails in
					PoolUnitResourceViewState(
						thumbnail: .known(resourceDetails.resource.metadata.iconURL),
						symbol: resourceDetails.resource.metadata.symbol ?? resourceDetails.resource.metadata.name ?? L10n.Account.PoolUnits.unknownSymbolName,
						tokenAmount: redemptionValue(for: resourceDetails)
					)
				}
		)! // Safe to unwrap, guaranteed to not be empty
	}
}
