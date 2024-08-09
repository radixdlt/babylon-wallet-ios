import ComposableArchitecture
import SwiftUI

extension NonFungibleTokenDetails.State {
	var viewState: NonFungibleTokenDetails.ViewState {
		.init(
			tokenDetails: token.map {
				NonFungibleTokenDetails.ViewState.TokenDetails(token: $0, stakeClaim: stakeClaim)
			},
			resourceThumbnail: ownedResource.map { .success($0.metadata.iconURL) } ?? resourceDetails.metadata.iconURL,
			resourceDetails: .init(
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
			),
			isClaimStakeEnabled: isClaimStakeEnabled
		)
	}
}

extension NonFungibleTokenDetails.ViewState.TokenDetails {
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

// MARK: - NonFungibleTokenList.Detail.View
extension NonFungibleTokenDetails {
	public struct ViewState: Equatable {
		let tokenDetails: TokenDetails?
		let resourceThumbnail: Loadable<URL?>
		let resourceDetails: AssetResourceDetailsSection.ViewState
		let isClaimStakeEnabled: Bool

		public struct TokenDetails: Equatable {
			let keyImage: URL?
			let nonFungibleGlobalID: NonFungibleGlobalId
			let name: String?
			let description: String?
			let stakeClaim: OnLedgerEntitiesClient.StakeClaim?
			let dataFields: [ArbitraryDataField]
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NonFungibleTokenDetails>

		public init(store: StoreOf<NonFungibleTokenDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				DetailsContainer(title: .success(viewStore.tokenDetails?.name ?? "")) {
					store.send(.view(.closeButtonTapped))
				} contents: {
					VStack(spacing: .zero) {
						if let tokenDetails = viewStore.tokenDetails {
							VStack(spacing: .medium3) {
								if let keyImage = tokenDetails.keyImage {
									NFTFullView(url: keyImage)
								}

								if let description = tokenDetails.description {
									ExpandableTextView(fullText: description)
										.textStyle(.body1Regular)
										.foregroundColor(.app.gray1)
									AssetDetailsSeparator()
										.padding(.horizontal, -.large2)
								}

								KeyValueView(nonFungibleGlobalID: tokenDetails.nonFungibleGlobalID, showLocalIdOnly: true)

								if let name = tokenDetails.name {
									KeyValueView(key: L10n.AssetDetails.NFTDetails.name, value: name)
								}

								if let stakeClaim = tokenDetails.stakeClaim {
									stakeClaimView(stakeClaim, isClaimStakeEnabled: viewStore.isClaimStakeEnabled) {
										viewStore.send(.tappedClaimStake)
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
							loadable(viewStore.resourceThumbnail) { url in
								Thumbnail(.nft, url: url, size: .veryLarge)
							}

							AssetResourceDetailsSection(viewState: viewStore.resourceDetails)
						}
						.padding(.vertical, .medium1)
						.background(.app.gray5, ignoresSafeAreaEdges: .bottom)
					}
				}
				.foregroundColor(.app.gray1)
				.task { @MainActor in
					await viewStore.send(.task).finish()
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
				.foregroundColor(.app.gray1)

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
