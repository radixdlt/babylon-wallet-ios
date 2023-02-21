import AccountDetailsFeature
import AccountListFeature
import AccountPortfolio
import AccountPreferencesFeature
import CreateEntityFeature
import FeaturePrelude
import TransactionSigningFeature

extension Home.State {
	var viewState: Home.ViewState {
		.init()
	}
}

// MARK: - Home.View
extension Home {
	struct ViewState: Equatable {}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<Home>

		public init(store: StoreOf<Home>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: \.viewState,
				send: { .view($0) }
			) { viewStore in
				NavigationStack {
					ScrollView {
						VStack(spacing: .medium1) {
							Header.View(
								store: store.scope(
									state: \.header,
									action: { .child(.header($0)) }
								)
							)

							AccountList.View(
								store: store.scope(
									state: \.accountList,
									action: { .child(.accountList($0)) }
								)
							)
							.padding(.horizontal, .medium1)

							Button(L10n.Home.CreateAccount.buttonTitle) {
								viewStore.send(.createAccountButtonTapped)
							}
							.buttonStyle(.secondaryRectangular())
						}
						.padding(.bottom, .medium1)
					}
					.refreshable {
						await viewStore.send(.pullToRefreshStarted).finish()
					}
//					ZStack {
//						IfLetStore(
//							store.scope(
//								state: \.createAccountCoordinator,
//								action: { .child(.createAccountCoordinator($0)) }
//							),
//							then: { CreateAccountCoordinator.View(store: $0) }
//						)
//						.zIndex(1)
//
//						IfLetStore(
//							store.scope(
//								state: \.accountPreferences,
//								action: { .child(.accountPreferences($0)) }
//							),
//							then: { AccountPreferences.View(store: $0) }
//						)
//						.zIndex(3)
//					}
					.onAppear {
						viewStore.send(.appeared)
					}
					.navigationDestination(
						store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
						state: /Home.Destinations.State.accountDetails,
						action: Home.Destinations.Action.accountDetails,
						destination: { AccountDetails.View(store: $0) }
					)
				}
				#if os(iOS)
				.navigationTransition(.default, interactivity: .pan)
				#endif
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct HomeView_Previews: PreviewProvider {
	static var previews: some SwiftUI.View {
		Home.View(
			store: .init(
				initialState: .previewValue,
				reducer: Home()
			)
		)
	}
}

extension Home.State {
	public static let previewValue = Home.State(
		header: .init()
	)
}
#endif
