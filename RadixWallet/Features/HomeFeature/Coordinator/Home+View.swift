import ComposableArchitecture
import SwiftUI

extension Home.State {
	var viewState: Home.ViewState {
		.init(
			hasNotification: shouldWriteDownPersonasSeedPhrase,
			showRadixBanner: showRadixBanner,
			totalFiatWorth: totalFiatWorth
		)
	}
}

// MARK: - Home.View
extension Home {
	public struct ViewState: Equatable {
		let hasNotification: Bool
		let showRadixBanner: Bool
		let totalFiatWorth: Loadable<FiatWorth>?
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<Home>

		public init(store: StoreOf<Home>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState) { viewStore in
				ScrollView {
					VStack(spacing: .medium1) {
						HeaderView()

						if let fiatWorth = viewStore.totalFiatWorth {
							VStack(spacing: .small2) {
								Text("TOTAL VALUE")
									.foregroundStyle(.app.gray2)
									.textStyle(.body1Header)
								TotalCurrencyWorthView(
									state: .init(totalCurrencyWorth: fiatWorth),
									backgroundColor: .app.gray4
								) {
									viewStore.send(.view(.showFiatWorthToggled))
								}
								.foregroundColor(.app.gray1)
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

						if viewStore.showRadixBanner {
							RadixBanner {
								store.send(.view(.radixBannerButtonTapped))
							} dismiss: {
								store.send(.view(.radixBannerDismissButtonTapped))
							}
							.transition(.scale(scale: 0.8).combined(with: .opacity))
						}
					}
					.padding(.bottom, .medium3)
				}
				.animation(.default, value: viewStore.showRadixBanner)
				.toolbar {
					ToolbarItem(placement: .navigationBarTrailing) {
						SettingsButton(shouldShowNotification: viewStore.hasNotification) {
							store.send(.view(.settingsButtonTapped))
						}
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
			.sheet(isPresented: .constant(true), content: {
				FeedbackView()
			})
		}

		private struct HeaderView: SwiftUI.View {
			var body: some SwiftUI.View {
				VStack(alignment: .leading, spacing: .small2) {
					Text(L10n.HomePage.title)
						.foregroundColor(.app.gray1)
						.textStyle(.sheetTitle)

					HStack {
						Text(L10n.HomePage.subtitle)
							.foregroundColor(.app.gray2)
							.textStyle(.body1HighImportance)
							.lineLimit(2)

						Spacer(minLength: 2 * .large1)
					}
				}
				.padding(.leading, .medium1)
				.padding(.top, .small3)
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
			.exportMnemonic(with: destinationStore)
			.importMnemonics(with: destinationStore)
			.acknowledgeJailbreakAlert(with: destinationStore)
	}

	private func accountDetails(with destinationStore: PresentationStoreOf<Home.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Home.Destination.State.accountDetails,
			action: Home.Destination.Action.accountDetails,
			destination: { AccountDetails.View(store: $0) }
		)
	}

	private func createAccount(with destinationStore: PresentationStoreOf<Home.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /Home.Destination.State.createAccount,
			action: Home.Destination.Action.createAccount,
			content: { CreateAccountCoordinator.View(store: $0) }
		)
	}

	private func exportMnemonic(with destinationStore: PresentationStoreOf<Home.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /Home.Destination.State.exportMnemonic,
			action: Home.Destination.Action.exportMnemonic,
			content: { ExportMnemonic.View(store: $0).inNavigationStack }
		)
	}

	private func importMnemonics(with destinationStore: PresentationStoreOf<Home.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /Home.Destination.State.importMnemonics,
			action: Home.Destination.Action.importMnemonics,
			content: { ImportMnemonicsFlowCoordinator.View(store: $0) }
		)
	}

	private func acknowledgeJailbreakAlert(with destinationStore: PresentationStoreOf<Home.Destination>) -> some View {
		alert(
			store: destinationStore,
			state: /Home.Destination.State.acknowledgeJailbreakAlert,
			action: Home.Destination.Action.acknowledgeJailbreakAlert
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

// MARK: - RadixBanner
struct RadixBanner: View {
	let action: () -> Void
	let dismiss: () -> Void

	var body: some View {
		VStack(spacing: 0) {
			Image(asset: AssetResource.radixBanner)
				.padding(.top, .medium1)

			Text(L10n.HomePage.RadixBanner.title)
				.textStyle(.body1Header)
				.foregroundColor(.app.gray1)
				.padding(.bottom, .small2)

			Text(L10n.HomePage.RadixBanner.subtitle)
				.multilineTextAlignment(.center)
				.textStyle(.body2Regular)
				.foregroundColor(.app.gray2)
				.padding(.horizontal, .huge3)
				.padding(.bottom, .medium3)

			Button(L10n.HomePage.RadixBanner.action, action: action)
				.buttonStyle(.secondaryRectangular(
					shouldExpand: true,
					trailingImage: .init(asset: AssetResource.iconLinkOut)
				))
				.padding([.horizontal, .bottom], .medium3)
		}
		.background(Color.app.gray5)
		.cornerRadius(.medium3)
		.overlay(alignment: .topTrailing) {
			CloseButton(action: dismiss)
				.padding(.small3)
		}
		.padding([.horizontal, .bottom], .medium3)
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
