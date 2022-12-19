import ComposableArchitecture
import DesignSystem
import EngineToolkit
import Resources
import SharedModels

// MARK: - NonFungibleTokenDetails.View
public extension NonFungibleTokenDetails {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<NonFungibleTokenDetails>

		public init(store: StoreOf<NonFungibleTokenDetails>) {
			self.store = store
		}
	}
}

public extension NonFungibleTokenDetails.View {
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
				}
			}
			.foregroundColor(.app.gray1)
		}
	}
}

// MARK: - NonFungibleTokenDetails.View.ViewState
extension NonFungibleTokenDetails.View {
	struct ViewState: Equatable {
		var displayID: String

		init(state: NonFungibleTokenDetails.State) {
			displayID = state.id.address
		}
	}
}

#if DEBUG

// MARK: - NonFungibleTokenDetails_Preview
struct NonFungibleTokenDetails_Preview: PreviewProvider {
	static var previews: some View {
		NonFungibleTokenDetails.View(
			store: .init(
				initialState: .previewValue,
				reducer: NonFungibleTokenDetails()
			)
		)
	}
}
#endif
