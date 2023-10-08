import EngineKit
import FeaturePrelude

extension LSUDetails.State {
	var viewState: LSUDetails.ViewState {
		.init(
			containerWithHeader: .init(
				title: .success(stakeUnitResource.resourceMetadata.name ?? L10n.Account.PoolUnits.unknownPoolUnitName),
				amount: stakeAmount.formatted(),
				symbol: .success(stakeUnitResource.resourceMetadata.symbol)
			),
			thumbnailURL: stakeUnitResource.resourceMetadata.iconURL,
			validatorNameViewState: .init(with: validator),
			redeemableTokenAmount: .init(.init(xrdAmount: xrdRedemptionValue.formatted())),
			resourceDetails: .init(
				description: .success(stakeUnitResource.resourceMetadata.description),
				resourceAddress: stakeUnitResource.resourceAddress,
				isXRD: false,
				validatorAddress: validator.address,
				resourceName: .success(stakeUnitResource.resourceMetadata.name), // TODO: Is this correct?
				currentSupply: .success(validator.xrdVaultBalance.formatted()),
				behaviors: .success(stakeUnitResource.behaviors),
				tags: .success(stakeUnitResource.resourceMetadata.tags)
			)
		)
	}
}

extension LSUDetails {
	public struct ViewState: Equatable {
		let containerWithHeader: DetailsContainerWithHeaderViewState
		let thumbnailURL: URL?

		let validatorNameViewState: ValidatorNameView.ViewState
		let redeemableTokenAmount: NonEmpty<IdentifiedArrayOf<PoolUnitResourceViewState>>
		let resourceDetails: AssetResourceDetailsSection.ViewState
	}

	public struct View: SwiftUI.View {
		private let store: StoreOf<LSUDetails>

		public init(store: StoreOf<LSUDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: \.viewState,
				send: LSUDetails.Action.view
			) { viewStore in
				DetailsContainerWithHeaderView(viewState: viewStore.containerWithHeader) {
					viewStore.send(.closeButtonTapped)
				} thumbnailView: {
					NFTThumbnail(viewStore.thumbnailURL, size: .veryLarge)
				} detailsView: {
					VStack(spacing: .medium1) {
						AssetDetailsSeparator()

						Text(L10n.Account.PoolUnits.Details.currentRedeemableValue)
							.textStyle(.secondaryHeader)
							.foregroundColor(.app.gray1)

						ValidatorNameView(viewState: viewStore.validatorNameViewState)
							.padding(.horizontal, .large2)

						PoolUnitResourcesView(resources: viewStore.redeemableTokenAmount)
							.padding(.horizontal, .large2)

						AssetResourceDetailsSection(viewState: viewStore.resourceDetails)
					}
					.padding(.bottom, .medium1)
				}
			}
		}
	}
}

extension ValidatorNameView.ViewState {
	init(
		with validator: OnLedgerEntity.Validator
	) {
		self.init(
			imageURL: validator.metadata.iconURL,
			name: validator.metadata.name ?? L10n.Account.PoolUnits.unknownValidatorName
		)
	}
}
