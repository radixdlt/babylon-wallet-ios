import ComposableArchitecture
import SwiftUI

extension Home.State {
	var viewState: Home.ViewState {
		.init(totalFiatWorth: showFiatWorth ? totalFiatWorth : nil)
	}
}

// MARK: - Home.View
extension Home {
	struct ViewState: Equatable {
		let totalFiatWorth: Loadable<FiatWorth>?
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<Home>

		init(store: StoreOf<Home>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState) { viewStore in
				ScrollView {
					VStack(spacing: .medium3) {
						CardCarousel.View(store: store.scope(state: \.carousel, action: \.child.carousel))

						if let fiatWorth = viewStore.totalFiatWorth {
							VStack(spacing: .small2) {
								Text(L10n.HomePage.totalValue)
									.foregroundStyle(.secondaryText)
									.textStyle(.body1Header)
									.textCase(.uppercase)

								TotalCurrencyWorthView(
									state: .init(totalCurrencyWorth: fiatWorth),
									backgroundColor: .tertiaryBackground
								) {
									viewStore.send(.view(.showFiatWorthToggled))
								}
								.foregroundColor(.primaryText)
							}
							.padding(.horizontal, .medium1)
						}

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
							store.send(.view(.createAccountButtonTapped))
						}
						.buttonStyle(.secondaryRectangular())
					}
					.padding(.bottom, .medium3)
					.padding(.top, .small1)
				}
				.toolbar {
					ToolbarItem(placement: .topBarLeading) {
						Text(L10n.HomePage.title)
							.foregroundColor(Color.primaryText)
							.textStyle(.sheetTitle)
							.padding(.leading, .medium3)
					}
					ToolbarItem(placement: .navigationBarTrailing) {
						Button {
							store.send(.view(.settingsButtonTapped))
						} label: {
							Image(.homeHeaderSettings)
						}
						.tint(Color.primaryText)
						.padding(.trailing, .medium3)
					}
				}
			}
			.refreshable {
				await store.send(.view(.pullToRefreshStarted)).finish()
			}
			.task { @MainActor in
				await store.send(.view(.task)).finish()
			}
			.destinations(with: store)
			.onFirstAppear {
				store.send(.view(.onFirstAppear))
			}
			.onDisappear {
				store.send(.view(.onDisappear))
			}
			.background(Color.primaryBackground)
		}
	}
}

private extension StoreOf<Home> {
	var destination: PresentationStoreOf<Home.Destination> {
		func scopeState(state: State) -> PresentationState<Home.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState) { .destination($0) }
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<Home>) -> some View {
		let destinationStore = store.destination
		return accountDetails(with: destinationStore)
			.createAccount(with: destinationStore)
			.acknowledgeJailbreakAlert(with: destinationStore)
			.userFeedback(with: destinationStore)
			.relinkConnector(with: destinationStore)
			.securityCenter(with: destinationStore)
			.p2pLinks(with: destinationStore)
			.dAppsDirectory(with: destinationStore)
	}

	private func accountDetails(with destinationStore: PresentationStoreOf<Home.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.accountDetails, action: \.accountDetails)) {
			AccountDetails.View(store: $0)
		}
	}

	private func createAccount(with destinationStore: PresentationStoreOf<Home.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.createAccount, action: \.createAccount)) {
			CreateAccountCoordinator.View(store: $0)
		}
	}

	private func acknowledgeJailbreakAlert(with destinationStore: PresentationStoreOf<Home.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.acknowledgeJailbreakAlert, action: \.acknowledgeJailbreakAlert))
	}

	private func userFeedback(with destinationStore: PresentationStoreOf<Home.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.npsSurvey, action: \.npsSurvey)) {
			NPSSurvey.View(store: $0)
		}
	}

	private func relinkConnector(with destinationStore: PresentationStoreOf<Home.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.relinkConnector, action: \.relinkConnector)) {
			NewConnection.View(store: $0)
		}
	}

	private func securityCenter(with destinationStore: PresentationStoreOf<Home.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.securityCenter, action: \.securityCenter)) {
			SecurityCenter.View(store: $0)
		}
	}

	private func p2pLinks(with destinationStore: PresentationStoreOf<Home.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.p2pLinks, action: \.p2pLinks)) {
			P2PLinksFeature.View(store: $0)
		}
	}

	private func dAppsDirectory(with destinationStore: PresentationStoreOf<Home.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.dAppsDirectory, action: \.dAppsDirectory)) {
			DAppsDirectory.View(store: $0)
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
	static let previewValue = Home.State()
}
#endif
