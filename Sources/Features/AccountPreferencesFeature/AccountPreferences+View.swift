import Common
import ComposableArchitecture
import DesignSystem
import SwiftUI

// MARK: - AccountPreferences.View
public extension AccountPreferences {
	@MainActor
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(
			store: Store
		) {
			self.store = store
		}
	}
}

public extension AccountPreferences.View {
	var body: some View {
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

					Form {
						Section {
							Button(L10n.AccountPreferences.faucetButtonTitle) {
								viewStore.send(.faucetButtonTapped)
							}
							.buttonStyle(.primaryText())
							.enabled(viewStore.isFaucetButtonEnabled)
						}
					}
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
		public var isFaucetButtonEnabled: Bool

		init(state: AccountPreferences.State) {
			isFaucetButtonEnabled = state.isFaucetButtonEnabled
		}
	}
}

// MARK: - AccountPreferences_Preview
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
