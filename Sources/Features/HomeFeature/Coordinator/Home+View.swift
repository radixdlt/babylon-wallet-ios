import AccountDetailsFeature
import AccountListFeature
import AccountPreferencesFeature
import Common
import ComposableArchitecture
import CreateAccountFeature
import DesignSystem
import IncomingConnectionRequestFromDappReviewFeature
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
							state: \.createAccount,
							action: { .child(.createAccount($0)) }
						),
						then: CreateAccount.View.init(store:)
					)
					.zIndex(1)

					IfLetStore(
						store.scope(
							state: \.accountDetails,
							action: { .child(.accountDetails($0)) }
						),
						then: AccountDetails.View.init(store:)
					)
					.zIndex(2)

					IfLetStore(
						store.scope(
							state: \.accountPreferences,
							action: { .child(.accountPreferences($0)) }
						),
						then: AccountPreferences.View.init(store:)
					)
					.zIndex(3)

					IfLetStore(
						store.scope(
							state: \.transfer,
							action: { .child(.transfer($0)) }
						),
						then: AccountDetails.Transfer.View.init(store:)
					)
					.zIndex(4)

					IfLetStore(
						store.scope(
							state: \.chooseAccountRequestFromDapp,
							action: { .child(.chooseAccountRequestFromDapp($0)) }
						),
						then: IncomingConnectionRequestFromDappReview.View.init(store:)
					)
					.zIndex(5)

					IfLetStore(
						store.scope(
							state: \.transactionSigning,
							action: { .child(.transactionSigning($0)) }
						),
						then: TransactionSigning.View.init(store:)
					)
					.zIndex(6)
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

			ScrollView {
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
					.buttonStyle(.secondary)

					Spacer()
				}
				.padding(.medium1)
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
				initialState: .placeholder,
				reducer: Home()
			)
		)
	}
}
#endif // DEBUG
