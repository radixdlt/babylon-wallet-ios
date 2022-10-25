import AccountDetailsFeature
import AccountListFeature
import AccountPreferencesFeature
import AggregatedValueFeature
import Common
import ComposableArchitecture
import CreateAccountFeature
import IncomingConnectionRequestFromDappReviewFeature
import SwiftUI

// MARK: - Home.View
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
			store,
			observe: ViewState.init(state:),
			send: Home.Action.init
		) { viewStore in
			ZStack {
				homeView(with: viewStore)
					.onAppear {
						viewStore.send(.didAppear)
					}
					.zIndex(0)

				IfLetStore(
					store.scope(
						state: \.createAccount,
						action: Home.Action.createAccount
					),
					then: CreateAccount.View.init(store:)
				)
				.zIndex(1)

				IfLetStore(
					store.scope(
						state: \.accountDetails,
						action: Home.Action.accountDetails
					),
					then: AccountDetails.View.init(store:)
				)
				.zIndex(1)

				IfLetStore(
					store.scope(
						state: \.accountPreferences,
						action: Home.Action.accountPreferences
					),
					then: AccountPreferences.View.init(store:)
				)
				.zIndex(2)

				IfLetStore(
					store.scope(
						state: \.transfer,
						action: Home.Action.transfer
					),
					then: AccountDetails.Transfer.View.init(store:)
				)
				.zIndex(2)

				#if DEBUG
				IfLetStore(
					store.scope(
						state: \.connectionRequest,
						action: Home.Action.connectionRequest
					),
					then: IncomingConnectionRequestFromDappReview.View.init(store:)
				)
				.zIndex(1)
				#endif
			}
		}
	}
}

// MARK: - Home.View.ViewAction
extension Home.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case createAccountButtonTapped
		case didAppear

		#if DEBUG
		case showDAppConnectionRequest
		#endif
	}
}

extension Home.Action {
	init(action: Home.View.ViewAction) {
		switch action {
		case .didAppear:
			self = .internal(.system(.viewDidAppear))
		case .createAccountButtonTapped:
			self = .internal(.user(.createAccountButtonTapped))

		#if DEBUG
		case .showDAppConnectionRequest:
			self = .internal(.user(.showDAppConnectionRequest))
		#endif
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
	// TODO: extract button for reuse
	func createAccountButton(action: @escaping () -> Void) -> some View {
		Button(action: action) {
			Text(L10n.CreateAccount.createNewAccount)
				.foregroundColor(.app.buttonTextBlack)
				.textStyle(.body2HighImportance)
				.padding(.horizontal, 40)
				.frame(height: 50)
				.background(Color.app.gray4)
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
			.padding([.leading, .trailing, .top], 24)

			ScrollView {
				LazyVStack(spacing: 24) {
					VStack {
						title
						AggregatedValue.View(
							store: store.scope(
								state: \.aggregatedValue,
								action: Home.Action.aggregatedValue
							)
						)
					}
					AccountList.View(
						store: store.scope(
							state: \.accountList,
							action: Home.Action.accountList
						)
					)
					createAccountButton {
						viewStore.send(.createAccountButtonTapped)
					}
					Spacer()

					#if DEBUG
					Button(
						action: { viewStore.send(.showDAppConnectionRequest) },
						label: {
							Text("dApp Connection Request")
								.padding()
								.background(Color.red)
								.cornerRadius(8)
								.foregroundColor(.yellow)
						}
					)

					Spacer()
					#endif

					Home.VisitHub.View(
						store: store.scope(
							state: \.visitHub,
							action: Home.Action.visitHub
						)
					)
				}
				.padding(24)
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
