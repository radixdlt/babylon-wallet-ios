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
			WithViewStore(store, observe: \.viewState, send: PoolUnit.Action.view) { viewStore in
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
			.destinations(with: store)
		}
	}
}

extension PoolUnit.State {
	var viewState: PoolUnit.ViewState {
		.init(
			iconURL: poolUnit.resource.metadata.iconURL,
			name: poolUnit.resource.metadata.name ?? L10n.Account.PoolUnits.unknownPoolUnitName,
			resources: resourceDetails.map { details in
				PoolUnitResourceViewState.viewStates(amount: poolUnit.resource.amount, resourcesDetails: details)
			},
			isSelected: isSelected
		)
	}
}

extension PoolUnitResourceViewState {
	static func viewStates(
		amount: RETDecimal,
		resourcesDetails: OnLedgerEntitiesClient.OwnedResourcePoolDetails
	) -> NonEmpty<IdentifiedArrayOf<PoolUnitResourceViewState>> {
		let xrdResourceViewState = resourcesDetails.xrdResource.map {
			PoolUnitResourceViewState(
				id: $0.resource.resourceAddress,
				thumbnail: .xrd,
				symbol: Constants.xrdTokenName,
				tokenAmount: $0.poolRedemptionValue(for: amount, poolUnitResource: resourcesDetails.poolUnitResource.resource)
			)
		}
		let nonXrdResources = resourcesDetails.nonXrdResources.map { resourceDetails in
			PoolUnitResourceViewState(
				id: resourceDetails.resource.resourceAddress,
				thumbnail: .known(resourceDetails.resource.metadata.iconURL),
				symbol: resourceDetails.resource.metadata.symbol ?? resourceDetails.resource.metadata.name ?? L10n.Account.PoolUnits.unknownSymbolName,
				tokenAmount: resourceDetails.poolRedemptionValue(for: amount, poolUnitResource: resourcesDetails.poolUnitResource.resource)
			)
		}

		return .init(
			rawValue: (xrdResourceViewState.map { [$0] } ?? []) + nonXrdResources
		)! // Safe to unwrap, guaranteed to not be empty
	}
}

private extension StoreOf<PoolUnit> {
	var destination: PresentationStoreOf<PoolUnit.Destination> {
		func scopeState(state: State) -> PresentationState<PoolUnit.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<PoolUnit>) -> some View {
		let destinationStore = store.destination
		return sheet(
			store: destinationStore,
			state: /PoolUnit.Destination.State.details,
			action: PoolUnit.Destination.Action.details,
			content: { PoolUnitDetails.View(store: $0) }
		)
	}
}
