import AccountDetailsFeature
import AccountListFeature
import AccountPreferencesFeature
import Common
import ComposableArchitecture
import CreateAccountFeature
import DesignSystem
import GrantDappWalletAccessFeature
import SwiftUI
import TransactionSigningFeature

// MARK: - Home.View
public extension Home {
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

public extension Home.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ForceFullScreen {
				ZStack {
					homeView(with: viewStore)
						.onAppear {
							viewStore.send(.didAppear)
						}
						.zIndex(0)

					IfLetStore(
						store.scope(
							state: \.createAccountFlow,
							action: { .child(.createAccountFlow($0)) }
						),
						then: { CreateAccountCoordinator.View(store: $0) }
					)
					.zIndex(1)

					IfLetStore(
						store.scope(
							state: \.accountDetails,
							action: { .child(.accountDetails($0)) }
						),
						then: { AccountDetails.View(store: $0) }
					)
					.zIndex(2)

					IfLetStore(
						store.scope(
							state: \.accountPreferences,
							action: { .child(.accountPreferences($0)) }
						),
						then: { AccountPreferences.View(store: $0) }
					)
					.zIndex(3)

					IfLetStore(
						store.scope(
							state: \.transfer,
							action: { .child(.transfer($0)) }
						),
						then: { AccountDetails.Transfer.View(store: $0) }
					)
					.zIndex(4)
				}
			}
		}
	}
}

// MARK: - Home.View.ViewState
extension Home.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: Home.State) {}
	}
}

private extension Home.View {
	func homeView(with viewStore: ViewStore<Home.View.ViewState, Home.Action.ViewAction>) -> some View {
		VStack {
			Home.Header.View(
				store: store.scope(
					state: \.header,
					action: { .child(.header($0)) }
				)
			)
			.padding(EdgeInsets(top: .medium1, leading: .large2, bottom: .zero, trailing: .medium1))

			RefreshableScrollView {
				LazyVStack(spacing: .medium1) {
					AccountList.View(
						store: store.scope(
							state: \.accountList,
							action: { .child(.accountList($0)) }
						)
					)

					Button(L10n.CreateAccount.createNewAccount) {
						viewStore.send(.createAccountButtonTapped)
					}
					.buttonStyle(.secondaryRectangular())

					Spacer()
				}
				.padding(.medium1)
			}
			.refreshable {
				await viewStore.send(.pullToRefreshStarted).finish()
			}
		}
	}
}

private extension Home.View {
	var title: some View {
		Text(L10n.AggregatedValue.title)
			.foregroundColor(.app.buttonTextBlack)
			.textStyle(.body2Header)
			.textCase(.uppercase)
	}
}

#if DEBUG

// MARK: - HomeView_Previews
struct HomeView_Previews: PreviewProvider {
	static var previews: some View {
		Home.View(
			store: .init(
				initialState: .previewValue,
				reducer: Home()
			)
		)
	}
}
#endif // DEBUG
