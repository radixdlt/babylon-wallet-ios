import EngineKit
import FeaturePrelude

extension NonFungibleTokenDetails.State {
	var viewState: NonFungibleTokenDetails.ViewState {
		.init(
			tokenDetails: token.map(NonFungibleTokenDetails.ViewState.TokenDetails.init),
			resourceThumbnail: prefetchedPortfolioResource.map { .success($0.metadata.iconURL) } ?? resource.resourceMetadata.iconURL,
			resourceDetails: .init(
				description: resource.resourceMetadata.description,
				resourceAddress: resourceAddress,
				isXRD: false,
				validatorAddress: nil,
				resourceName: resource.resourceMetadata.name,
				currentSupply: resource.totalSupply.map { $0?.formatted() },
				behaviors: resource.behaviors,
				tags: prefetchedPortfolioResource.map { .success($0.metadata.tags) } ?? resource.resourceMetadata.tags
			)
		)
	}
}

extension NonFungibleTokenDetails.ViewState.TokenDetails {
	init(token: OnLedgerEntity.NonFungibleToken) {
		self.init(
			keyImage: token.data.keyImageURL,
			nonFungibleGlobalID: token.id,
			name: token.data.name,
			description: token.data.description
		)
	}
}

// extension AssetResourceDetailsSection.ViewState {
//	init(resource: OnLedgerEntity.Resource) {
//		self.init(
//			description: resource.description,
//			resourceAddress: resource.resourceAddress,
//			isXRD: false,
//			validatorAddress: nil,
//			resourceName: resource.name,
//			currentSupply: resource.totalSupply?.formatted(),
//			behaviors: resource.behaviors,
//			tags: resource.tags
//		)
//	}
// }

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
				DetailsContainer(title: .success(viewStore.tokenDetails?.name ?? "")) {
					store.send(.view(.closeButtonTapped))
				} contents: {
					VStack(spacing: .medium1) {
						if let tokenDetails = viewStore.tokenDetails {
							VStack(spacing: .medium3) {
								if let keyImage = tokenDetails.keyImage {
									NFTFullView(url: keyImage)
								}

								KeyValueView(nonFungibleGlobalID: tokenDetails.nonFungibleGlobalID)
							}
							.lineLimit(1)
							.frame(maxWidth: .infinity, alignment: .leading)
							.padding(.horizontal, .large2)
						}

						VStack(spacing: .medium1) {
							loadable(viewStore.resourceThumbnail) { value in
								NFTThumbnail(value, size: .veryLarge)
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
					await viewStore.send(.view(.task)).finish()
				}
			}
		}
	}
}
