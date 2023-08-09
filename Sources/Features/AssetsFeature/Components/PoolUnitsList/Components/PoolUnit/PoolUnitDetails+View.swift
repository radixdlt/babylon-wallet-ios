import EngineKit
import FeaturePrelude

extension PoolUnitDetails.State {
	var viewState: PoolUnitDetails.ViewState {
		let poolUnitResource = poolUnit.poolUnitResource
		return .init(
			containerWithHeader: .init(
				displayName: poolUnitResource.name ?? "Unknown",
				thumbnail: .known(poolUnitResource.iconURL),
				amount: poolUnitResource.amount.format(),
				symbol: poolUnitResource.symbol
			),
			resources: poolUnit.resourceViewStates,
			description: poolUnitResource.description,
			resourceAddress: poolUnitResource.resourceAddress,
			name: poolUnitResource.name ?? "Uknown",
			currentSupply: poolUnitResource.totalSupply?.format() ?? "Unknown"
		)
	}
}

// MARK: - PoolUnitDetails.View
extension PoolUnitDetails {
	public struct ViewState: Equatable {
		let containerWithHeader: DetailsContainerWithHeaderViewState

		let resources: NonEmpty<IdentifiedArrayOf<PoolUnitResourceViewState>>

		let description: String?

		let resourceAddress: ResourceAddress
		let name: String
		let currentSupply: String
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<PoolUnitDetails>

		public init(store: StoreOf<PoolUnitDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: \.viewState,
				send: PoolUnitDetails.Action.view
			) { viewStore in
				DetailsContainerWithHeaderView(viewState: viewStore.containerWithHeader) {
					VStack(spacing: .medium1) {
						// FIXME: Localize
						Text("Current Redeemable Value")
							.textStyle(.secondaryHeader)
							.foregroundColor(.app.gray1)
						PoolUnitResourcesView(
							resources: viewStore.resources
						)

						DetailsContainerWithHeaderViewMaker
							.makeSeparator()

						DetailsContainerWithHeaderViewMaker
							.makeDescriptionView(description: viewStore.description)

						VStack(spacing: .medium3) {
							TokenDetailsPropertyViewMaker
								.makeAddress(resourceAddress: viewStore.resourceAddress)
							TokenDetailsPropertyView(
								// FIXME: Localize
								title: "Name",
								propertyView: Text(viewStore.name)
							)
							TokenDetailsPropertyView(
								// FIXME: Localize
								title: "Current Supply",
								propertyView: Text(viewStore.currentSupply)
							)
						}
					}
				} closeButtonAction: {
					viewStore.send(.closeButtonTapped)
				}
			}
		}
	}
}
