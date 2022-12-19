import ComposableArchitecture
import DesignSystem
import EngineToolkit
import Resources
import SharedModels

// MARK: - NonFungibleTokenList.Detail.View
public extension NonFungibleTokenList.Detail {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<NonFungibleTokenList.Detail>

		public init(store: StoreOf<NonFungibleTokenList.Detail>) {
			self.store = store
		}
	}
}

public extension NonFungibleTokenList.Detail.View {
	var body: some View {
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
								Text("NFT ID")
									.textStyle(.body1Regular)
									.foregroundColor(.app.gray2)
								Text(viewStore.nftID)
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
										Text("Resource Address")
											.textStyle(.body1Regular)
											.foregroundColor(.app.gray2)
										AddressView(
											viewStore.resourceAddress,
											textStyle: .body1Regular,
											copyAddressAction: {
												viewStore.send(.copyAddressButtonTapped)
											}
										)
										.frame(maxWidth: .infinity, alignment: .trailing)
										.multilineTextAlignment(.trailing)
									}
									if let name = viewStore.resourceName {
										HStack {
											Text("Name")
												.textStyle(.body1Regular)
												.foregroundColor(.app.gray2)
											Text(name)
												.frame(maxWidth: .infinity, alignment: .trailing)
												.multilineTextAlignment(.trailing)
										}
									}
								}
								.padding(.horizontal, .large2)
								divider
							}
							.padding(.vertical, .medium1)
						}
					}
				}
			}
			.foregroundColor(.app.gray1)
		}
	}

	var headerIconAsset: ImageAsset {
		// TODO: implement depending on the API design
		AssetResource.nft
	}
}

// MARK: - NonFungibleTokenList.Detail.View.ViewState
extension NonFungibleTokenList.Detail.View {
	struct ViewState: Equatable {
		var nftID: String
		var description: String?
		var resourceAddress: AddressView.ViewState
		var resourceName: String?

		init(state: NonFungibleTokenList.Detail.State) {
			nftID = state.asset.id.stringRepresentation
			description = state.container.description
			resourceAddress = .init(
				address: state.container.resourceAddress.address,
				format: .short()
			)
			resourceName = state.container.name
		}
	}
}

#if DEBUG

// MARK: - NonFungibleTokenDetails_Preview
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
