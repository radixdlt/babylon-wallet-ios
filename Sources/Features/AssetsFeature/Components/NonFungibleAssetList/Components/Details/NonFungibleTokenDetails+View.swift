import EngineKit
import FeaturePrelude

extension NonFungibleTokenDetails.State {
	var viewState: NonFungibleTokenDetails.ViewState {
		.init(
			keyImage: token.keyImageURL,
			nonFungibleGlobalID: token.id,
			name: token.name,
			description: token.description,
			resourceThumbnail: resource.iconURL,
			resourceDetails: .init(
				description: resource.description,
				resourceAddress: resource.resourceAddress,
				validatorAddress: nil,
				resourceName: resource.name,
				currentSupply: nil, // FIXME: Find actual value
				behaviors: resource.behaviors,
				tags: resource.tags
			)
		)
	}
}

// MARK: - NonFungibleTokenList.Detail.View
extension NonFungibleTokenDetails {
	public struct ViewState: Equatable {
		let keyImage: URL?
		let nonFungibleGlobalID: NonFungibleGlobalId
		let name: String?
		let description: String?
		let resourceThumbnail: URL?
		let resourceDetails: AssetResourceDetailsSection.ViewState
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NonFungibleTokenDetails>

		public init(store: StoreOf<NonFungibleTokenDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView(showsIndicators: false) {
					VStack(spacing: .medium1) {
						VStack(spacing: .medium3) {
							if let keyImage = viewStore.keyImage {
								NFTFullView(url: keyImage)
							}

							KeyValueView(nonFungibleGlobalID: viewStore.nonFungibleGlobalID)

							if let name = viewStore.name {
								KeyValueView(key: L10n.AssetDetails.NFTDetails.name, value: name)
							}
						}
						.lineLimit(1)
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(.horizontal, .large2)

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
