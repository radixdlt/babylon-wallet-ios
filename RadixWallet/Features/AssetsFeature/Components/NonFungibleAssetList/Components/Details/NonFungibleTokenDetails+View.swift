import ComposableArchitecture
import SwiftUI

extension NonFungibleTokenDetails.State {
	var tokenDetails: TokenDetails? {
		token.map {
			.init(token: $0, stakeClaim: stakeClaim)
		}
	}

	var title: Loadable<String?> {
		if let name = tokenDetails?.name {
			.success(name)
		} else {
			resourceDetails.metadata.name
		}
	}

	var resourceThumbnail: Loadable<URL?> {
		ownedResource.map { .success($0.metadata.iconURL) } ?? resourceDetails.metadata.iconURL
	}

	var token: OnLedgerEntity.NonFungibleToken? {
		details?.token?.token
	}

	var amount: ResourceAmount? {
		details?.amount
	}

	var resourceDetailsViewState: AssetResourceDetailsSection.ViewState {
		.init(
			description: resourceDetails.metadata.description,
			infoUrl: resourceDetails.metadata.infoURL,
			resourceAddress: resourceAddress,
			isXRD: false,
			validatorAddress: nil,
			resourceName: resourceDetails.metadata.name,
			currentSupply: resourceDetails.totalSupply.map { $0?.formatted() },
			divisibility: nil,
			arbitraryDataFields: resourceDetails.metadata.arbitraryItems.asDataFields,
			behaviors: resourceDetails.behaviors,
			tags: ownedResource.map { .success($0.metadata.tags) } ?? resourceDetails.metadata.tags
		)
	}

	struct TokenDetails: Equatable {
		let keyImage: URL?
		let nonFungibleGlobalID: NonFungibleGlobalId
		let name: String?
		let description: String?
		let stakeClaim: OnLedgerEntitiesClient.StakeClaim?
		let dataFields: [ArbitraryDataField]
	}
}

extension NonFungibleTokenDetails.State.TokenDetails {
	init(token: OnLedgerEntity.NonFungibleToken, stakeClaim: OnLedgerEntitiesClient.StakeClaim?) {
		self.init(
			keyImage: token.data?.keyImageURL,
			nonFungibleGlobalID: token.id,
			name: token.data?.name,
			description: token.data?.tokenDescription?.nilIfEmpty,
			stakeClaim: stakeClaim,
			dataFields: token.data?.arbitraryDataFields ?? []
		)
	}
}

// MARK: - NonFungibleTokenDetails.View
extension NonFungibleTokenDetails {
	struct View: SwiftUI.View {
		let store: StoreOf<NonFungibleTokenDetails>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				DetailsContainer(title: store.title) {
					store.send(.view(.closeButtonTapped))
				} contents: {
					WithPerceptionTracking {
						VStack(spacing: .zero) {
							if let tokenDetails = store.tokenDetails {
								VStack(spacing: .medium3) {
									if let keyImage = tokenDetails.keyImage {
										NFTFullView(url: keyImage)
									}

									if let description = tokenDetails.description {
										ExpandableTextView(fullText: description)
											.textStyle(.body1Regular)
											.foregroundColor(.primaryText)
										AssetDetailsSeparator()
											.padding(.horizontal, -.large2)
									}

									KeyValueView(nonFungibleGlobalID: tokenDetails.nonFungibleGlobalID, showLocalIdOnly: true)

									if let name = tokenDetails.name {
										KeyValueView(key: L10n.AssetDetails.NFTDetails.name, value: name)
									}

									if let stakeClaim = tokenDetails.stakeClaim {
										stakeClaimView(stakeClaim, isClaimStakeEnabled: store.isClaimStakeEnabled) {
											store.send(.view(.tappedClaimStake))
										}
									}

									if !tokenDetails.dataFields.isEmpty {
										AssetDetailsSeparator()
											.padding(.horizontal, -.large2)

										ForEachStatic(tokenDetails.dataFields) { field in
											ArbitraryDataFieldView(field: field)
										}
									}
								}
								.lineLimit(1)
								.frame(maxWidth: .infinity, alignment: .leading)
								.padding(.top, .small1)
								.padding(.horizontal, .large2)
								.padding(.bottom, .medium1)
							}

							VStack(spacing: .medium1) {
								VStack(spacing: .medium3) {
									loadable(store.resourceThumbnail) { url in
										Thumbnail(.nft, url: url, size: .veryLarge)
									}

									if let amount = store.amount {
										ResourceBalanceView.AmountView(amount: .init(amount), appearance: .large)
									}
								}

								AssetResourceDetailsSection(viewState: store.resourceDetailsViewState)

								if let childStore = store.scope(state: \.hideResource, action: \.child.hideResource) {
									HideResource.View(store: childStore)
										.padding(.vertical, .medium1)
								}
							}
							.padding(.vertical, .medium1)
							.background(.secondaryBackground)
						}
					}
				}
				.foregroundColor(.primaryText)
				.task { @MainActor in
					await store.send(.view(.task)).finish()
				}
			}
		}
	}
}

extension NonFungibleTokenDetails.View {
	fileprivate func stakeClaimView(
		_ stakeClaim: OnLedgerEntitiesClient.StakeClaim,
		isClaimStakeEnabled: Bool,
		onClaimTap: @escaping () -> Void
	) -> some SwiftUI.View {
		VStack(spacing: .medium3) {
			AssetDetailsSeparator()
				.padding(.horizontal, -.large2)

			Text(L10n.AssetDetails.Staking.currentRedeemableValue)
				.textStyle(.secondaryHeader)
				.foregroundColor(.primaryText)

			ResourceBalanceView(
				.fungible(.xrd(balance: stakeClaim.claimAmount, network: stakeClaim.validatorAddress.networkID)),
				appearance: .standard
			)
			.padding(.horizontal, .medium3)
			.padding(.vertical, .medium2)
			.roundedCorners(strokeColor: .app.gray4)

			if stakeClaim.isReadyToBeClaimed, isClaimStakeEnabled {
				Button(L10n.AssetDetails.Staking.readyToClaim, action: onClaimTap)
					.buttonStyle(.primaryRectangular)
			} else if let unstakingDurationDescription = stakeClaim.unstakingDurationDescription {
				KeyValueView(key: L10n.AssetDetails.Staking.readyToClaimIn, value: unstakingDurationDescription)
			}
		}
		.padding(.top, .small2)
	}
}

extension OnLedgerEntitiesClient.StakeClaim {
	var unstakingDurationDescription: String? {
		guard let reamainingEpochsUntilClaim, isUnstaking else {
			return nil
		}
		typealias S = L10n.AssetDetails.Staking
		let remainingMinutes = reamainingEpochsUntilClaim * epochDurationInMinutes
		let remainingHours = remainingMinutes / 60
		let remainingDays = remainingHours / 24
		if remainingDays > 0 {
			return remainingDays == 1 ? S.readyToClaimInDay : S.readyToClaimInDays(remainingDays)
		} else if remainingHours > 0 {
			return remainingHours == 1 ? S.readyToClaimInHour : S.readyToClaimInHours(remainingHours)
		} else {
			return remainingMinutes == 1 ? S.readyToClaimInMinute : S.readyToClaimInMinutes(remainingMinutes)
		}
	}
}

extension OnLedgerEntity.NonFungibleToken.NFTData {
	private static let standardFields = OnLedgerEntity.NonFungibleToken.NFTData.StandardField.allCases

	fileprivate var arbitraryDataFields: [ArbitraryDataField] {
		fields.compactMap { field in
			guard let fieldName = field.fieldName,
			      let kind = field.fieldKind,
			      !Self.standardFields.map(\.rawValue).contains(fieldName) // Filter out standard fields
			else {
				return nil
			}
			return .init(kind: kind, name: fieldName, isLocked: false)
		}
	}
}
