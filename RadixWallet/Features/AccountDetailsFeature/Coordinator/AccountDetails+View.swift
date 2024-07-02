import ComposableArchitecture
import SwiftUI

extension AccountDetails.State {
	var viewState: AccountDetails.ViewState {
		.init(
			accountAddress: account.address,
			appearanceID: account.appearanceID,
			displayName: account.displayName.rawValue,
			isLedgerAccount: account.isLedgerControlled,
			totalFiatWorth: showFiatWorth ? assets.totalFiatWorth : nil,
			account: account,
			securityProblemsConfig: securityProblemsConfig
		)
	}
}

// MARK: - AccountDetails.View
extension AccountDetails {
	public struct ViewState: Equatable {
		let accountAddress: AccountAddress
		let appearanceID: AppearanceID
		let displayName: String
		let isLedgerAccount: Bool
		let totalFiatWorth: Loadable<FiatWorth>?
		let account: Account
		let securityProblemsConfig: EntitySecurityProblemsView.Config
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AccountDetails>

		public init(store: StoreOf<AccountDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				HeaderListViewContainer(
					headerView: { header(with: viewStore) },
					listView: { assetsView() }
				)
				.ignoresSafeArea(edges: .bottom)
				.background(viewStore.appearanceID.gradient)
				.navigationBarBackButtonHidden()
				.task {
					await viewStore.send(.task).finish()
				}
				.onDisappear {
					viewStore.send(.onDisappear)
				}
				.toolbar {
					ToolbarItem(placement: .principal) {
						Text(viewStore.displayName)
							.foregroundColor(.white)
							.textStyle(.body1Header)
					}

					ToolbarItem(placement: .navigationBarLeading) {
						BackButton {
							viewStore.send(.backButtonTapped)
						}
						.foregroundColor(.app.white)
					}

					ToolbarItem(placement: .navigationBarTrailing) {
						Button(asset: AssetResource.ellipsis) {
							viewStore.send(.preferencesButtonTapped)
						}
						.frame(.small)
						.foregroundColor(.app.white)
					}
				}
			}
			.destinations(with: store)
		}

		@ViewBuilder
		func header(with viewStore: ViewStore<AccountDetails.ViewState, AccountDetails.ViewAction>) -> some SwiftUI.View {
			AddressView(.address(.account(viewStore.accountAddress, isLedgerHWAccount: viewStore.isLedgerAccount)))
				.foregroundColor(.app.whiteTransparent)
				.textStyle(.body2HighImportance)
				.padding(.bottom, .small1)

			if let totalFiatWorth = viewStore.totalFiatWorth {
				TotalCurrencyWorthView(
					state: .init(totalCurrencyWorth: totalFiatWorth),
					backgroundColor: .clear
				) {
					viewStore.send(.showFiatWorthToggled)
				}
				.foregroundColor(.app.white)
				.padding(.horizontal, .medium1)
			}

			HStack(spacing: .medium3) {
				historyButton()
				transferButton()
			}
			.padding(.top, .small1)
			.padding([.horizontal, .bottom], .medium1)

			EntitySecurityProblemsView(config: viewStore.securityProblemsConfig) {
				viewStore.send(.securityProblemsTapped)
			}
			.padding([.horizontal, .bottom], .medium1)
		}

		func assetsView() -> some SwiftUI.View {
			AssetsView.View(store: store.scope(state: \.assets, action: \.child.assets))
				.roundedCorners(.top, radius: .medium1)
				.ignoresSafeArea(edges: .bottom)
		}

		func transferButton() -> some SwiftUI.View {
			Button(L10n.Account.transfer, asset: AssetResource.transfer) {
				store.send(.view(.transferButtonTapped))
			}
			.buttonStyle(.header)
		}

		func historyButton() -> some SwiftUI.View {
			Button {
				store.send(.view(.historyButtonTapped))
			} label: {
				HStack(alignment: .center) {
					Label(L10n.Common.history, asset: AssetResource.iconHistory)
				}
			}
			.buttonStyle(.header)
		}
	}
}

// MARK: - HeaderButtonStyle

extension ButtonStyle where Self == HeaderButtonStyle {
	public static var header: HeaderButtonStyle { .init() }
}

// MARK: - HeaderButtonStyle
public struct HeaderButtonStyle: ButtonStyle {
	public func makeBody(configuration: ButtonStyle.Configuration) -> some View {
		configuration.label
			.textStyle(.body1Header)
			.frame(maxWidth: .infinity)
			.foregroundColor(.app.white)
			.frame(height: .standardButtonHeight)
			.background(.app.whiteTransparent3)
			.cornerRadius(.standardButtonHeight / 2)
			.opacity(configuration.isPressed ? 0.4 : 1)
	}
}

private extension StoreOf<AccountDetails> {
	var destination: PresentationStoreOf<AccountDetails.Destination> {
		func scopeState(state: State) -> PresentationState<AccountDetails.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<AccountDetails>) -> some SwiftUI.View {
		let destinationStore = store.destination
		return preferences(with: destinationStore)
			.history(with: destinationStore)
			.transfer(with: destinationStore)
			.fungibleDetails(with: destinationStore)
			.nonFungibleDetails(with: destinationStore)
			.stakeUnitDetails(with: destinationStore)
			.stakeClaimDetails(with: destinationStore)
			.poolUnitDetails(with: destinationStore)
			.securityCenter(with: destinationStore)
	}

	private func preferences(with destinationStore: PresentationStoreOf<AccountDetails.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.preferences, action: \.preferences)) {
			AccountPreferences.View(store: $0)
		}
	}

	private func history(with destinationStore: PresentationStoreOf<AccountDetails.Destination>) -> some View {
		fullScreenCover(store: destinationStore.scope(state: \.history, action: \.history)) {
			TransactionHistory.View(store: $0)
		}
	}

	private func transfer(with destinationStore: PresentationStoreOf<AccountDetails.Destination>) -> some View {
		fullScreenCover(store: destinationStore.scope(state: \.transfer, action: \.transfer)) {
			AssetTransfer.SheetView(store: $0)
		}
	}

	private func fungibleDetails(with destinationStore: PresentationStoreOf<AccountDetails.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.fungibleDetails, action: \.fungibleDetails)) {
			FungibleTokenDetails.View(store: $0)
		}
	}

	private func nonFungibleDetails(with destinationStore: PresentationStoreOf<AccountDetails.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.nonFungibleDetails, action: \.nonFungibleDetails)) {
			NonFungibleTokenDetails.View(store: $0)
		}
	}

	private func stakeUnitDetails(with destinationStore: PresentationStoreOf<AccountDetails.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.stakeUnitDetails, action: \.stakeUnitDetails)) {
			LSUDetails.View(store: $0)
		}
	}

	private func stakeClaimDetails(with destinationStore: PresentationStoreOf<AccountDetails.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.stakeClaimDetails, action: \.stakeClaimDetails)) {
			NonFungibleTokenDetails.View(store: $0)
		}
	}

	private func poolUnitDetails(with destinationStore: PresentationStoreOf<AccountDetails.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.poolUnitDetails, action: \.poolUnitDetails)) {
			PoolUnitDetails.View(store: $0)
		}
	}

	private func securityCenter(with destinationStore: PresentationStoreOf<AccountDetails.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.securityCenter, action: \.securityCenter)) {
			SecurityCenter.View(store: $0)
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

struct AccountDetails_Preview: PreviewProvider {
	static var previews: some View {
		NavigationStack {
			AccountDetails.View(
				store: .init(
					initialState: .init(accountWithInfo: .init(account: .previewValue0), showFiatWorth: true),
					reducer: AccountDetails.init
				)
			)
			.navigationBarTitleDisplayMode(.inline)
		}
	}
}
#endif
