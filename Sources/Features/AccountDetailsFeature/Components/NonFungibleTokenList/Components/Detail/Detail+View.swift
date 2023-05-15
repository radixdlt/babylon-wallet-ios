import FeaturePrelude

extension NonFungibleTokenList.Detail.State {
	var viewState: NonFungibleTokenList.Detail.ViewState {
		.init(
			keyImage: token.keyImageURL,
			nonFungibleGlobalID: resource.nftGlobalID(for: token.id),
			name: token.name,
			description: token.description,
			resourceName: resource.name,
			resourceThumbnail: resource.iconURL,
			resourceDescription: resource.description,
			resourceAddress: resource.resourceAddress
		)
	}
}

// MARK: - NonFungibleTokenList.Detail.View
extension NonFungibleTokenList.Detail {
	public struct ViewState: Equatable {
		let keyImage: URL?
		let nonFungibleGlobalID: AccountPortfolio.NonFungibleResource.GlobalID
		let name: String?
		let description: String?
		let resourceName: String?
		let resourceThumbnail: URL?
		let resourceDescription: String?
		let resourceAddress: ResourceAddress
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NonFungibleTokenList.Detail>

		public init(store: StoreOf<NonFungibleTokenList.Detail>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				NavigationStack {
					ScrollView {
						VStack(spacing: .medium1) {
							VStack(spacing: .medium3) {
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
										KeyValueView(key: L10n.AssetDetails.resourceAddress) {
											AddressView(.address(.resource(viewStore.resourceAddress)))
										}

										if let name = viewStore.resourceName {
											KeyValueView(key: L10n.AssetDetails.NFTDetails.resourceName, value: name)
										}
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
					#if os(iOS)
					.toolbar {
						ToolbarItem(placement: .navigationBarLeading) {
							CloseButton { viewStore.send(.closeButtonTapped) }
						}
					}
					#endif
				}
				.foregroundColor(.app.gray1)
			}
		}
	}
}

extension AccountPortfolio.NonFungibleResource {
	// TODO: unit test
	func nftAddress(for id: NonFungibleToken.ID) -> String {
		resourceAddress.address + ":" + id.rawValue
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
// struct NonFungibleTokenListDetail_Preview: PreviewProvider {
//	static var previews: some View {
//		NonFungibleTokenList.Detail.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: NonFungibleTokenList.Detail()
//			)
//		)
//	}
// }
//
// extension NonFungibleTokenList.Detail.State {
//	public static let previewValue = Self(
//		resource: .init(resourceAddress: .init(address: "resource_tdx_c_1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq40v2wv"), tokens: []),
//		localId_: .init("#1#")
//	)
// }
// #endif
