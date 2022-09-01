import Common
import ComposableArchitecture
import SwiftUI

public extension Home {
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
			store.scope(
				state: ViewState.init,
				action: Home.Action.init
			)
		) { viewStore in
			ZStack {
				homeView(with: viewStore)
					.zIndex(0)

				IfLetStore(
					store.scope(
						state: \.createAccount,
						action: Home.Action.createAccount
					),
					then: Home.CreateAccount.View.init(store:)
				)
				.zIndex(1)

				IfLetStore(
					store.scope(
						state: \.accountDetails,
						action: Home.Action.accountDetails
					),
					then: Home.AccountDetails.View.init(store:)
				)
				.zIndex(2)

				IfLetStore(
					store.scope(
						state: \.accountPreferences,
						action: Home.Action.accountPreferences
					),
					then: Home.AccountPreferences.View.init(store:)
				)
				.zIndex(3)

				IfLetStore(
					store.scope(
						state: \.transfer,
						action: Home.Action.transfer
					),
					then: Home.Transfer.View.init(store:)
				)
				.zIndex(5)
			}
		}
	}
}

extension Home.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case createAccountButtonTapped
	}
}

extension Home.Action {
	init(action: Home.View.ViewAction) {
		switch action {
		case .createAccountButtonTapped:
			self = .internal(.user(.createAccountButtonTapped))
		}
	}
}

extension Home.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: Home.State) {}
	}
}

private extension Home.View {
	// TODO: extract button for reuse
	func createAccountButton(action: @escaping () -> Void) -> some View {
		Button(action: action) {
			Text(L10n.Home.createNewAccount)
				.foregroundColor(.app.buttonTextBlack)
				.font(.app.subhead)
				.padding(.horizontal, 40)
				.frame(height: 50)
				.background(Color.app.buttonBackgroundLight)
				.cornerRadius(6)
		}
	}

	func homeView(with viewStore: ViewStore<Home.View.ViewState, Home.View.ViewAction>) -> some View {
		VStack {
			Home.Header.View(
				store: store.scope(
					state: \.header,
					action: Home.Action.header
				)
			)
			.padding([.leading, .trailing, .top], 32)

			ScrollView {
				LazyVStack(spacing: 25) {
					VStack {
						title
						Home.AggregatedValue.View(
							store: store.scope(
								state: \.aggregatedValue,
								action: Home.Action.aggregatedValue
							)
						)
					}
					Home.AccountList.View(
						store: store.scope(
							state: \.accountList,
							action: Home.Action.accountList
						)
					)
					createAccountButton {
						viewStore.send(.createAccountButtonTapped)
					}
					Spacer()
					Home.VisitHub.View(
						store: store.scope(
							state: \.visitHub,
							action: Home.Action.visitHub
						)
					)
				}
				.padding(32)
			}
		}
	}
}

private extension Home.View {
	var title: some View {
		Text(L10n.Home.AggregatedValue.title)
			.foregroundColor(.app.buttonTextBlack)
			.font(.app.caption1)
			.textCase(.uppercase)
	}
}

/*
 // MARK: - HomeView_Previews
 struct HomeView_Previews: PreviewProvider {
 	static var previews: some View {
 		Home.View(
 			store: .init(
 				initialState: .placeholder,
 				reducer: Home.reducer,
 				environment: .placeholder
 			)
 		)
 	}
 }
 */
