import FeaturePrelude

extension AccountPreferences.State {
	var viewState: AccountPreferences.ViewState {
		#if DEBUG
		return .init(faucetButtonState: faucetButtonState, createFungibleTokenButtonState: createFungibleTokenButtonState)
		#else
		return .init(faucetButtonState: faucetButtonState)
		#endif // DEBUG
	}
}

// MARK: - AccountPreferences.View
extension AccountPreferences {
	public struct ViewState: Equatable {
		public var faucetButtonState: ControlState

		#if DEBUG
		public var createFungibleTokenButtonState: ControlState
		#endif // DEBUG

		#if DEBUG
		public init(faucetButtonState: ControlState, createFungibleTokenButtonState: ControlState) {
			self.faucetButtonState = faucetButtonState
			self.createFungibleTokenButtonState = createFungibleTokenButtonState
		}
		#else
		public init(faucetButtonState: ControlState) {
			self.faucetButtonState = faucetButtonState
		}
		#endif // DEBUG
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AccountPreferences>

		public init(store: StoreOf<AccountPreferences>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				NavigationStack {
					VStack(alignment: .leading) {
						faucetButton(with: viewStore)
						#if DEBUG
						createFungibleTokenButton(with: viewStore)
						#endif // DEBUG
					}
					.frame(maxHeight: .infinity, alignment: .top)
					.padding(.medium1)
					.onAppear {
						viewStore.send(.appeared)
					}
					.navigationTitle(L10n.AccountPreferences.title)
					#if os(iOS)
						.navigationBarTitleColor(.app.gray1)
						.navigationBarTitleDisplayMode(.inline)
						.navigationBarInlineTitleFont(.app.secondaryHeader)
						.toolbar {
							ToolbarItem(placement: .navigationBarLeading) {
								CloseButton {
									viewStore.send(.closeButtonTapped)
								}
							}
						}
					#endif // os(iOS)
				}
			}
		}
	}
}

extension AccountPreferences.View {
	@ViewBuilder
	private func faucetButton(with viewStore: ViewStoreOf<AccountPreferences>) -> some View {
		Button(L10n.AccountPreferences.faucetButtonTitle) {
			viewStore.send(.faucetButtonTapped)
		}
		.buttonStyle(.secondaryRectangular(shouldExpand: true))
		.controlState(viewStore.faucetButtonState)

		if viewStore.faucetButtonState.isLoading {
			Text(L10n.AccountPreferences.loadingPrompt)
				.font(.app.body2Regular)
				.foregroundColor(.app.gray1)
		}
	}
}

#if DEBUG
extension AccountPreferences.View {
	@ViewBuilder
	private func createFungibleTokenButton(with viewStore: ViewStoreOf<AccountPreferences>) -> some View {
		Button("Create Fungible Token") {
			viewStore.send(.createFungibleTokenButtonTapped)
		}
		.buttonStyle(.secondaryRectangular(shouldExpand: true))
		.controlState(viewStore.createFungibleTokenButtonState)

		if viewStore.createFungibleTokenButtonState.isLoading {
			Text("Creating Token")
				.font(.app.body2Regular)
				.foregroundColor(.app.gray1)
		}
	}
}

#endif // DEBUG

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct AccountPreferences_Preview: PreviewProvider {
	static var previews: some View {
		AccountPreferences.View(
			store: .init(
				initialState: .init(address: try! .init(address: "account-address-deadbeef")),
				reducer: AccountPreferences()
			)
		)
	}
}
#endif
