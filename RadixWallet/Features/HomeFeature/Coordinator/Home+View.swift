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
				ScrollView {
					VStack(spacing: .medium1) {
						Header.View(
							store: store.scope(
								state: \.header,
								action: { .child(.header($0)) }
							)
						)

						VStack(spacing: .medium3) {
							ForEachStore(
								store.scope(
									state: \.accountRows,
									action: { .child(.account(id: $0, action: $1)) }
								),
								content: { Home.AccountRow.View(store: $0) }
							)
						}
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
				.destinations(with: store)
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

private extension StoreOf<Home> {
	var destination: PresentationStoreOf<Home.Destination> {
		scope(state: \.$destination) { .child(.destination($0)) }
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<Home>) -> some View {
		let destinationStore = store.destination
		return accountDetails(with: destinationStore)
			.createAccount(with: destinationStore)
			.exportMnemonic(with: destinationStore)
			.importMnemonics(with: destinationStore)
	}

	func accountDetails(with destinationStore: PresentationStoreOf<Home.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Home.Destination.State.accountDetails,
			action: Home.Destination.Action.accountDetails,
			destination: { AccountDetails.View(store: $0) }
		)
	}

	func createAccount(with destinationStore: PresentationStoreOf<Home.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /Home.Destination.State.createAccount,
			action: Home.Destination.Action.createAccount,
			content: { CreateAccountCoordinator.View(store: $0) }
		)
	}

	func exportMnemonic(with destinationStore: PresentationStoreOf<Home.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /Home.Destination.State.exportMnemonic,
			action: Home.Destination.Action.exportMnemonic,
			content: { childStore in
				NavigationStack {
					ExportMnemonic.View(store: childStore)
				}
			}
		)
	}

	func importMnemonics(with destinationStore: PresentationStoreOf<Home.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /Home.Destination.State.importMnemonics,
			action: Home.Destination.Action.importMnemonics,
			content: { ImportMnemonicsFlowCoordinator.View(store: $0) }
		)
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
	public static let previewValue = Home.State()
}
#endif
