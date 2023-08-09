import EngineKit
import FeaturePrelude

extension PoolUnitDetails.State {
	var viewState: PoolUnitDetails.ViewState {
		// FIXME: Rewire
		.init(
			containerWithHeader: .init(
				displayName: "temp",
				thumbnail: .xrd,
				amount: "2312.213223",
				symbol: "SYM"
			),
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
			)!,
			description: "Radaswap’s Lending pool token for the Radaswap pool, used to pay network usage fees and stake to support network security.",
			resourceAddress: .init(address: "yoyoyoy", decodedKind: .globalAccount),
			name: "Radix Token",
			currentSupply: "9,743,724,898.2"
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

						Separator().padding(.horizontal, -.small2)

						if let description = viewStore.description {
							Text(description)
								.textStyle(.body1Regular)
								.frame(maxWidth: .infinity, alignment: .leading)

							Separator().padding(.horizontal, -.small2)
						}
						VStack(spacing: .medium3) {
							HStack {
								Text(L10n.AssetDetails.resourceAddress)
									.textStyle(.body1Regular)
									.foregroundColor(.app.gray2)

								Spacer(minLength: .zero)

								AddressView(.address(.resource(viewStore.resourceAddress)))
									.textStyle(.body1HighImportance)
							}
							HStack {
								Text("Name")
									.textStyle(.body1Regular)
									.foregroundColor(.app.gray2)

								Spacer(minLength: .zero)

								Text(viewStore.name)
									.textStyle(.body1HighImportance)
							}
							HStack {
								Text("Current Supply")
									.textStyle(.body1Regular)
									.foregroundColor(.app.gray2)

								Spacer(minLength: .zero)

								Text(viewStore.currentSupply)
									.textStyle(.body1HighImportance)
							}
						}
					}
					.padding(.vertical, .medium3)
				} closeButtonAction: {
					viewStore.send(.closeButtonTapped)
				}
			}
		}
	}
}
