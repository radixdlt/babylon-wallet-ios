import ComposableArchitecture
import SwiftUI

extension LSUDetails.State {
	var containerWithHeader: DetailsContainerWithHeaderViewState {
		.init(
			title: .success(stakeUnitResource.resource.metadata.title),
			amount: stakeUnitResource.amount,
			currencyWorth: nil,
			symbol: .success(stakeUnitResource.resource.metadata.symbol)
		)
	}

	var thumbnailURL: URL? {
		stakeUnitResource.resource.metadata.iconURL
	}

	var validatorNameViewState: ValidatorHeaderView.ViewState {
		.init(with: validator)
	}

	var redeemableTokenAmount: ResourceBalance.ViewState.Fungible {
		.xrd(balance: xrdRedemptionValue, network: validator.address.networkID)
	}

	var resourceDetails: AssetResourceDetailsSection.ViewState {
		.init(
			description: .success(stakeUnitResource.resource.metadata.description),
			infoUrl: .success(stakeUnitResource.resource.metadata.infoURL),
			resourceAddress: stakeUnitResource.resource.resourceAddress,
			isXRD: false,
			validatorAddress: validator.address,
			resourceName: .success(stakeUnitResource.resource.metadata.title),
			currentSupply: .success(validator.xrdVaultBalance.formatted()),
			divisibility: .success(stakeUnitResource.resource.divisibility),
			arbitraryDataFields: .success(stakeUnitResource.resource.metadata.arbitraryItems.asDataFields),
			behaviors: .success(stakeUnitResource.resource.behaviors),
			tags: .success(stakeUnitResource.resource.metadata.tags)
		)
	}
}

// MARK: - LSUDetails.View
extension LSUDetails {
	struct View: SwiftUI.View {
		let store: StoreOf<LSUDetails>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				DetailsContainerWithHeaderView(viewState: store.containerWithHeader) {
					store.send(.view(.closeButtonTapped))
				} thumbnailView: {
					Thumbnail(.nft, url: store.thumbnailURL, size: .veryLarge)
				} detailsView: {
					VStack(spacing: .medium1) {
						AssetDetailsSeparator()

						Text(L10n.Account.PoolUnits.Details.currentRedeemableValue)
							.textStyle(.secondaryHeader)
							.foregroundColor(.app.gray1)

						ValidatorHeaderView(viewState: store.validatorNameViewState)
							.padding(.horizontal, .large2)

						ResourceBalanceView(
							.fungible(store.redeemableTokenAmount),
							appearance: .standard,
							hasBorder: true
						)
						.padding(.horizontal, .large2)

						AssetResourceDetailsSection(viewState: store.resourceDetails)
					}
					.padding(.bottom, .medium1)
				}
			}
		}
	}
}

extension ValidatorHeaderView.ViewState {
	init(
		with validator: OnLedgerEntity.Validator
	) {
		self.init(
			imageURL: validator.metadata.iconURL,
			name: validator.metadata.name,
			stakedAmount: nil
		)
	}
}
