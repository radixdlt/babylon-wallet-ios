import FeaturePrelude

// MARK: - AccountPreferences.View
extension AccountPreferences {
	@MainActor
	public struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(
			store: Store
		) {
			self.store = store
		}
	}
}

extension AccountPreferences.View {
	public var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ForceFullScreen {
				VStack {
					NavigationBar(
						titleText: L10n.AccountPreferences.title,
						leadingItem: BackButton {
							viewStore.send(.dismissButtonTapped)
						}
					)
					.foregroundColor(.app.gray1)
					.padding([.horizontal, .top], .medium3)

					VStack(alignment: .leading) {
						Spacer()
							.frame(height: .large1)

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

						Spacer()
					}
					.padding([.horizontal, .bottom], .medium1)
				}
				.onAppear {
					viewStore.send(.didAppear)
				}
			}
		}
	}
}

// MARK: - AccountPreferences.View.ViewState
extension AccountPreferences.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		public var faucetButtonState: ControlState

		init(state: AccountPreferences.State) {
			faucetButtonState = state.faucetButtonState
		}
	}
}

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
