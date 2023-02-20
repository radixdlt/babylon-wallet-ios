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
					ZStack {
						homeView(with: viewStore)
							.onAppear {
								viewStore.send(.appeared)
							}
							.zIndex(0)

						IfLetStore(
							store.scope(
								state: \.createAccountCoordinator,
								action: { .child(.createAccountCoordinator($0)) }
							),
							then: { CreateAccountCoordinator.View(store: $0) }
						)
						.zIndex(1)

						IfLetStore(
							store.scope(
								state: \.accountPreferences,
								action: { .child(.accountPreferences($0)) }
							),
							then: { AccountPreferences.View(store: $0) }
						)
						.zIndex(3)
					}
					.navigationDestination(
						store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
						state: /Home.Destinations.State.accountDetails,
						action: Home.Destinations.Action.accountDetails,
						destination: { AccountDetails.View(store: $0) }
					)
				}
				.navigationTransition(.default, interactivity: .pan)
			}
		}

		fileprivate func homeView(with viewStore: ViewStore<Home.ViewState, Home.ViewAction>) -> some SwiftUI.View {
			VStack {
				Header.View(
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

						Button(L10n.Home.CreateAccount.buttonTitle) {
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

		fileprivate var title: some SwiftUI.View {
			Text(L10n.AggregatedValue.title)
				.foregroundColor(.app.buttonTextBlack)
				.textStyle(.body2Header)
				.textCase(.uppercase)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct HomeView_Previews: PreviewProvider {
	static var previews: some SwiftUI.View {
		let _ = configureWalletAppUIAppearance()
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
