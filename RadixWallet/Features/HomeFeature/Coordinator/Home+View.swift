import ComposableArchitecture
import SwiftUI
extension Home.State {
	var viewState: Home.ViewState {
		.init(hasNotification: false) // we don't have any notification to show at the moment
	}
}

// MARK: - Home.View
extension Home {
	public struct ViewState: Equatable {
		let hasNotification: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<Home>

		public init(store: StoreOf<Home>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
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

							Button(L10n.HomePage.createNewAccount) {
								viewStore.send(.createAccountButtonTapped)
							}
							.buttonStyle(.secondaryRectangular())
						}
						.padding(.bottom, .medium1)
					}
					.toolbar {
						ToolbarItem(placement: .navigationBarTrailing) {
							SettingsButton(shouldShowNotification: viewStore.hasNotification) {
								viewStore.send(.settingsButtonTapped)
							}
						}
					}
					.refreshable {
						await viewStore.send(.pullToRefreshStarted).finish()
					}
					.task { @MainActor in
						await viewStore.send(.task).finish()
					}
					.navigationDestination(
						store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
						state: /Home.Destinations.State.accountDetails,
						action: Home.Destinations.Action.accountDetails,
						destination: { AccountDetails.View(store: $0) }
					)
					.sheet(
						store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
						state: /Home.Destinations.State.createAccount,
						action: Home.Destinations.Action.createAccount,
						content: { CreateAccountCoordinator.View(store: $0) }
					)
				}
				.navigationTransition(.default, interactivity: .pan)
			}
		}

		private struct SettingsButton: SwiftUI.View {
			let shouldShowNotification: Bool
			let action: () -> Void

			var body: some SwiftUI.View {
				Button(action: action) {
					Image(asset: AssetResource.homeHeaderSettings)
						.badged(shouldShowNotification)
				}
			}
		}
	}
}

extension View {
	public func badged(_ showBadge: Bool) -> some View {
		overlay(alignment: .topTrailing) {
			if showBadge {
				Circle()
					.fill(.app.notification)
					.frame(width: .small1, height: .small1) // we should probably have the frame size aligned with the unit size.
					.offset(x: .small3, y: -.small3)
			}
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI
struct HomeView_Previews: PreviewProvider {
	static var previews: some SwiftUI.View {
		Home.View(
			store: .init(
				initialState: .previewValue,
				reducer: Home.init
			)
		)
	}
}

extension Home.State {
	public static let previewValue = Home.State(
		babylonAccountRecoveryIsNeeded: false
	)
}
#endif
