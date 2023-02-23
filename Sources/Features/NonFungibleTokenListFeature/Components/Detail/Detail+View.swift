import FeaturePrelude

// MARK: - NonFungibleTokenList.Detail.View
extension NonFungibleTokenList.Detail {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NonFungibleTokenList.Detail>

		public init(store: StoreOf<NonFungibleTokenList.Detail>) {
			self.store = store
		}
	}
}

extension NonFungibleTokenList.Detail.View {
	public var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			VStack(spacing: .medium2) {
				NavigationBar(
					titleText: nil,
					leadingItem: CloseButton { viewStore.send(.closeButtonTapped) }
				)
				.padding([.horizontal, .top], .medium3)

				ScrollView {
					VStack(spacing: .medium1) {
						VStack(spacing: .medium3) {
							HStack {
								Text(L10n.NftList.Detail.nftID)
									.textStyle(.body1Regular)
									.foregroundColor(.app.gray2)
								AddressView(
									viewStore.nftID,
									textStyle: .body1Regular,
									copyAddressAction: {
										viewStore.send(.copyAddressButtonTapped(viewStore.state.fullNFTAddress))
									}
								)
								.frame(maxWidth: .infinity, alignment: .trailing)
								.multilineTextAlignment(.trailing)
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
										AddressView(
											viewStore.resourceAddress,
											textStyle: .body1Regular,
											copyAddressAction: {
												viewStore.send(.copyAddressButtonTapped(viewStore.state.fullResourceAddress))
											}
										)
										.frame(maxWidth: .infinity, alignment: .trailing)
										.multilineTextAlignment(.trailing)
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
				}
			}
			.foregroundColor(.app.gray1)
		}
	}

	public var headerIconAsset: ImageAsset {
		// TODO: implement depending on the API design
		AssetResource.nft
	}
}

// MARK: - NonFungibleTokenList.Detail.View.ViewState
extension NonFungibleTokenList.Detail.View {
	struct ViewState: Equatable {
		var nftID: AddressView.ViewState
		var fullNFTAddress: String
		var description: String?
		var resourceAddress: AddressView.ViewState
		var fullResourceAddress: String
		var resourceName: String?

		init(state: NonFungibleTokenList.Detail.State) {
			nftID = .init(address: state.asset.id.stringRepresentation)
			fullNFTAddress = state.container.nftAddress(for: state.asset)
			description = state.container.description
			resourceAddress = .init(
				address: state.container.resourceAddress.address,
				format: .default
			)
			fullResourceAddress = state.container.resourceAddress.address
			resourceName = state.container.name
		}
	}
}

extension NonFungibleTokenContainer {
	// TODO: unit test
	func nftAddress(for asset: NonFungibleToken) -> String {
		resourceAddress.address + ":" + asset.id.stringRepresentation
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
#endif
