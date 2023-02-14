import AccountDetailsFeature
import AccountListFeature
import AccountPreferencesFeature
import CreateEntityFeature
import FeaturePrelude
import TransactionSigningFeature

// MARK: - Home.View
extension Home {
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

extension Home.View {
	public var body: some View {
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
							state: \.createAccountCoordinator,
							action: { .child(.createAccountCoordinator($0)) }
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

extension Home.View {
	fileprivate func homeView(with viewStore: ViewStore<Home.View.ViewState, Home.Action.ViewAction>) -> some View {
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
}

extension Home.View {
	fileprivate var title: some View {
		Text(L10n.AggregatedValue.title)
			.foregroundColor(.app.buttonTextBlack)
			.textStyle(.body2Header)
			.textCase(.uppercase)
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

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
#endif
