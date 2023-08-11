import EngineKit
import FeaturePrelude

extension NonFungibleTokenDetails.State {
	var viewState: NonFungibleTokenDetails.ViewState {
		.init(
			keyImage: token.keyImageURL,
			nonFungibleGlobalID: token.id,
			name: token.name,
			description: token.description,
			resourceName: resource.name,
			resourceThumbnail: resource.iconURL,
			resourceDescription: resource.description,
			resourceAddress: resource.resourceAddress,
			behaviors: behaviors
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
		let resourceName: String?
		let resourceThumbnail: URL?
		let resourceDescription: String?
		let resourceAddress: ResourceAddress
		let behaviors: [AssetBehavior]
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

							KeyValueView(key: L10n.AssetDetails.NFTDetails.id) {
								AddressView(.identifier(.nonFungibleGlobalID(viewStore.nonFungibleGlobalID)))
							}

							if let name = viewStore.name {
								KeyValueView(key: L10n.AssetDetails.NFTDetails.name, value: name)
							}
						}
						.lineLimit(1)
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(.horizontal, .large2)

						ZStack {
							Color.app.gray5.edgesIgnoringSafeArea(.bottom)

							VStack(spacing: .medium1) {
								NFTThumbnail(viewStore.resourceThumbnail, size: .veryLarge)

								let divider = Color.app.gray4.frame(height: 1).padding(.horizontal, .medium1)
								if let description = viewStore.resourceDescription {
									divider
									Text(description)
										.textStyle(.body1Regular)
										.frame(maxWidth: .infinity, alignment: .leading)
										.padding(.horizontal, .large2)
								}

								divider

								VStack(spacing: .medium3) {
									KeyValueView(resourceAddress: viewStore.resourceAddress)

									if let name = viewStore.resourceName {
										KeyValueView(key: L10n.AssetDetails.NFTDetails.resourceName, value: name)
									}

									AssetBehaviorSection(behaviors: viewStore.behaviors)
								}
								.padding(.horizontal, .large2)
								.textStyle(.body1Regular)
								.lineLimit(1)
							}
							.padding(.vertical, .medium1)
						}
					}
					.padding(.top, .small1)
				}
				.foregroundColor(.app.gray1)
			}
		}
	}
}
