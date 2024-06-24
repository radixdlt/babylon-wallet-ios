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
				resourceAddress: resourceAddress,
				isXRD: false,
				validatorAddress: nil,
				resourceName: resourceDetails.metadata.title,
				currentSupply: resourceDetails.totalSupply.map { $0?.formatted() },
				behaviors: resourceDetails.behaviors,
				tags: ownedResource.map { .success($0.metadata.tags) } ?? resourceDetails.metadata.tags
			)
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
					VStack(spacing: .medium1) {
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

								KeyValueView(nonFungibleGlobalID: tokenDetails.nonFungibleGlobalID)

								if let stakeClaim = tokenDetails.stakeClaim {
									stakeClaimView(stakeClaim) {
										viewStore.send(.tappedClaimStake)
									}
								}

								if !tokenDetails.dataFields.isEmpty {
									AssetDetailsSeparator()
										.padding(.horizontal, -.large2)
								}

								ForEachStatic(tokenDetails.dataFields) { field in
									ArbitraryDataFieldView(field: field) { action in
										viewStore.send(.arbitraryDataField(action))
									}
								}
							}
							.lineLimit(1)
							.frame(maxWidth: .infinity, alignment: .leading)
							.padding(.horizontal, .large2)
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
					.padding(.top, .small1)
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
		onClaimTap: @escaping () -> Void
	) -> some SwiftUI.View {
		VStack(alignment: .leading, spacing: .small3) {
			ResourceBalanceView.StakeClaimNFT.Tokens(
				viewState: .init(
					canClaimTokens: true,
					stakeClaims: [stakeClaim]
				),
				background: .app.white,
				onClaimAllTapped: onClaimTap
			)

			if let unstakingDurationDescription = stakeClaim.unstakingDurationDescription {
				Text(unstakingDurationDescription)
					.textStyle(.body2HighImportance)
					.foregroundColor(.app.gray2)
			}
		}
	}
}

extension OnLedgerEntitiesClient.StakeClaim {
	var unstakingDurationDescription: String? {
		guard let reamainingEpochsUntilClaim, isUnstaking else {
			return nil
		}
		return L10n.AssetDetails.Staking.unstaking(
			reamainingEpochsUntilClaim * epochDurationInMinutes
		)
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
			return .init(kind: kind, name: fieldName)
		}
	}
}
