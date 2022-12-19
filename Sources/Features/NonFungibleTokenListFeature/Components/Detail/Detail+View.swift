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
								Text(viewStore.displayID)
									.frame(maxWidth: .infinity, alignment: .trailing)
									.multilineTextAlignment(.trailing)
							}
						}
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(.horizontal, .large2)
						.textStyle(.body1Regular)
						.lineLimit(1)

						VStack(alignment: .leading, spacing: .medium3) {
							Text("Associated dApp")
								.textStyle(.body1Regular)
								.foregroundColor(.app.gray2)
								.padding(.horizontal, .large2)

							Header(
								name: viewStore.containerName ?? "",
								iconAsset: headerIconAsset,
								isExpanded: false
							)
							.padding(.horizontal, .medium3)
						}
						.padding(.vertical, .medium1)
						.background(Color.app.gray5)
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
		var displayID: String
		var containerName: String?

		init(state: NonFungibleTokenList.Detail.State) {
			displayID = state.id.address
			containerName = state.name
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
