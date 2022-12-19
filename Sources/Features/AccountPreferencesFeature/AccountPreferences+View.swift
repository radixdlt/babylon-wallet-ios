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

					VStack {
						Spacer()
							.frame(height: .large1)

						Button(L10n.AccountPreferences.faucetButtonTitle) {
							viewStore.send(.faucetButtonTapped)
						}
						.buttonStyle(.secondaryRectangular(shouldExpand: true))
						.enabled(viewStore.isFaucetButtonEnabled)
						.isLoading(viewStore.isLoading, context: .local)

						if viewStore.isLoading {
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
		public var isFaucetButtonEnabled: Bool
		public var isLoading: Bool

		init(state: AccountPreferences.State) {
			isFaucetButtonEnabled = state.isFaucetButtonEnabled
			isLoading = state.isLoading
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
