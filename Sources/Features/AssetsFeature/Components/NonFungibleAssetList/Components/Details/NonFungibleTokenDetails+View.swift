import EngineKit
import FeaturePrelude

extension NonFungibleTokenDetails.State {
	var viewState: NonFungibleTokenDetails.ViewState {
		.init(
			tokenDetails: token.map(NonFungibleTokenDetails.ViewState.TokenDetails.init),
			resourceThumbnail: resource.iconURL,
			resourceDetails: .init(resource: resource)
		)
	}
}

extension NonFungibleTokenDetails.ViewState.TokenDetails {
	init(token: AccountPortfolio.NonFungibleResource.NonFungibleToken) {
		self.init(
			keyImage: token.keyImageURL,
			nonFungibleGlobalID: token.id,
			name: token.name,
			description: token.description
		)
	}
}

extension AssetResourceDetailsSection.ViewState {
	init(resource: OnLedgerEntity.Resource) {
		self.init(
			description: resource.description,
			resourceAddress: resource.resourceAddress,
			isXRD: false,
			validatorAddress: nil,
			resourceName: resource.name,
			currentSupply: resource.totalSupply?.format(),
			behaviors: resource.behaviors,
			tags: resource.tags
		)
	}
}

// MARK: - NonFungibleTokenList.Detail.View
extension NonFungibleTokenDetails {
	public struct ViewState: Equatable {
		let tokenDetails: TokenDetails?
		let resourceThumbnail: URL?
		let resourceDetails: AssetResourceDetailsSection.ViewState

		public struct TokenDetails: Equatable {
			let keyImage: URL?
			let nonFungibleGlobalID: NonFungibleGlobalId
			let name: String?
			let description: String?
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NonFungibleTokenDetails>

		public init(store: StoreOf<NonFungibleTokenDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState) { viewStore in
				ScrollView(showsIndicators: false) {
					VStack(spacing: .medium1) {
						if let tokenDetails = viewStore.tokenDetails {
							VStack(spacing: .medium3) {
								if let keyImage = tokenDetails.keyImage {
									NFTFullView(url: keyImage)
								}

								KeyValueView(nonFungibleGlobalID: tokenDetails.nonFungibleGlobalID)

								if let name = tokenDetails.name {
									KeyValueView(key: L10n.AssetDetails.NFTDetails.name, value: name)
								}
							}
							.lineLimit(1)
							.frame(maxWidth: .infinity, alignment: .leading)
							.padding(.horizontal, .large2)
						}

						VStack(spacing: .medium1) {
							NFTThumbnail(viewStore.resourceThumbnail, size: .veryLarge)

							AssetResourceDetailsSection(viewState: viewStore.resourceDetails)
						}
						.padding(.vertical, .medium1)
						.background(.app.gray5, ignoresSafeAreaEdges: .bottom)
					}
					.padding(.top, .small1)
				}
				.foregroundColor(.app.gray1)
			}
		}
	}
}
