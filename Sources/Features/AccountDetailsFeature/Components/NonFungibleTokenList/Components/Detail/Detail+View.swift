import FeaturePrelude

extension NonFungibleTokenList.Detail.State {
	var viewState: NonFungibleTokenList.Detail.ViewState {
		.init(
			nonFungibleGlobalID: resource.nftGlobalID(for: localId),
			resourceAddress: resource.resourceAddress,
			description: resource.description,
			resourceName: resource.name
		)
	}
}

// MARK: - NonFungibleTokenList.Detail.View
extension NonFungibleTokenList.Detail {
	public struct ViewState: Equatable {
		let nonFungibleGlobalID: AccountPortfolio.NonFungibleResource.GlobalID
		let resourceAddress: ResourceAddress
		let description: String?
		let resourceName: String?
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
								HStack {
									Text(L10n.NftList.Detail.nftID)
										.textStyle(.body1Regular)
										.foregroundColor(.app.gray2)

									Spacer()

									AddressView(.identifier(.nonFungibleGlobalID(viewStore.nonFungibleGlobalID)))
								}
							}
							.frame(maxWidth: .infinity, alignment: .leading)
							.padding(.horizontal, .large2)
							.textStyle(.body1Regular)
							.lineLimit(1)

							ZStack {
								Color.app.gray5.edgesIgnoringSafeArea(.bottom)

								VStack(spacing: .medium1) {
									Image(asset: headerIconAsset)
										.resizable()
										.frame(width: 104, height: 104)
										.clipShape(RoundedRectangle(cornerRadius: .small1, style: .circular))

									let divider = Color.app.gray4.frame(height: 1).padding(.horizontal, .medium1)
									if let description = viewStore.description {
										divider
										Text(description)
											.textStyle(.body1Regular)
											.frame(maxWidth: .infinity, alignment: .leading)
											.padding(.horizontal, .large2)
									}

									divider

									VStack(spacing: .medium3) {
										HStack {
											Text(L10n.NftList.Detail.resourceAddress)
												.textStyle(.body1Regular)
												.foregroundColor(.app.gray2)

											Spacer()

											AddressView(.address(.resource(viewStore.resourceAddress)))
										}
										if let name = viewStore.resourceName {
											HStack {
												Text(L10n.NftList.Detail.resourceName)
													.textStyle(.body1Regular)
													.foregroundColor(.app.gray2)
												Text(name)
													.frame(maxWidth: .infinity, alignment: .trailing)
													.multilineTextAlignment(.trailing)
											}
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

		public var headerIconAsset: ImageAsset {
			// TODO: implement depending on the API design
			AssetResource.nft
		}
	}
}

extension AccountPortfolio.NonFungibleResource {
	// TODO: unit test
	func nftAddress(for id: NonFungibleToken.ID) -> String {
		resourceAddress.address + ":" + id.rawValue
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct NonFungibleTokenListDetail_Preview: PreviewProvider {
	static var previews: some View {
		NonFungibleTokenList.Detail.View(
			store: .init(
				initialState: .previewValue,
				reducer: NonFungibleTokenList.Detail()
			)
		)
	}
}

extension NonFungibleTokenList.Detail.State {
	public static let previewValue = Self(
		resource: .init(resourceAddress: .init(address: "some"), tokens: []),
		localId: .init("#1#")
	)
}
#endif
