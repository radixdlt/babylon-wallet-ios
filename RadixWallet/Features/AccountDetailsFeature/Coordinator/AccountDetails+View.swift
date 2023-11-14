import ComposableArchitecture
import SwiftUI
extension AccountDetails.State {
	var viewState: AccountDetails.ViewState {
		.init(
			accountAddress: account.address,
			appearanceID: account.appearanceID,
			displayName: account.displayName.rawValue,
			mnemonicHandlingCallToAction: mnemonicHandlingCallToAction,
			isLedgerAccount: account.isLedgerAccount,
			showToolbar: destination == nil
		)
	}
}

// MARK: - AccountDetails.View
extension AccountDetails {
	public struct ViewState: Equatable {
		let accountAddress: AccountAddress
		let appearanceID: Profile.Network.Account.AppearanceID
		let displayName: String
		let mnemonicHandlingCallToAction: MnemonicHandling?
		let isLedgerAccount: Bool
		let showToolbar: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AccountDetails>

		public init(store: StoreOf<AccountDetails>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .zero) {
					AddressView(.address(.account(viewStore.accountAddress, isLedgerHWAccount: viewStore.isLedgerAccount)))
						.foregroundColor(.app.whiteTransparent)
						.textStyle(.body2HighImportance)
						.padding(.bottom, .medium1)

					prompts(
						mnemonicHandlingCallToAction: viewStore.mnemonicHandlingCallToAction
					)
					.padding(.medium1)

					HStack {
						historyButton()
						transferButton()
					}

					AssetsView.View(store: store.scope(state: \.assets, action: { .child(.assets($0)) }))
						.roundedCorners(.top, radius: .medium1)
						.ignoresSafeArea(edges: .bottom)
				}
				.background(viewStore.appearanceID.gradient)
				.navigationBarBackButtonHidden()
				.task {
					viewStore.send(.task)
				}
				.navigationTitle(viewStore.displayName)
				.navigationBarTitleColor(.white)
				.toolbar {
					if viewStore.showToolbar {
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
			}
			.destinations(store.scope(state: \.$destination, action: { .child(.destination($0)) }))
		}

		@ViewBuilder
		func prompts(mnemonicHandlingCallToAction: MnemonicHandling?) -> some SwiftUI.View {
			if let mnemonicHandlingCallToAction {
				switch mnemonicHandlingCallToAction {
				case .mustBeImported:
					importMnemonicPromptView {
						store.send(.view(.importMnemonicButtonTapped))
					}
				case .shouldBeExported:
					exportMnemonicPromptView {
						store.send(.view(.exportMnemonicButtonTapped))
					}
				}
			}
		}

		func transferButton() -> some SwiftUI.View {
			Button(L10n.Account.transfer, asset: AssetResource.transfer) {
				store.send(.view(.transferButtonTapped))
			}
			.headerButtonStyle
		}

		func historyButton() -> some SwiftUI.View {
			Button {
				store.send(.view(.historyButtonTapped))
			} label: {
				HStack(alignment: .center) {
					Label(L10n.Common.history, asset: AssetResource.iconHistory)
					Image(asset: AssetResource.iconLinkOut)
						.resizable()
						.renderingMode(.template)
						.frame(width: .medium3, height: .medium3)
						.opacity(0.5)
				}
			}
			.headerButtonStyle
		}
	}
}

private extension Button {
	var headerButtonStyle: some View {
		textStyle(.body1Header)
			.foregroundColor(.app.white)
			.padding(.horizontal, .large2)
			.frame(height: .standardButtonHeight)
			.background(.app.whiteTransparent3)
			.cornerRadius(.standardButtonHeight / 2)
			.padding(.bottom, .medium1)
	}
}

@MainActor
private extension View {
	func destinations(_ destinationStore: PresentationStoreOf<AccountDetails.Destinations>) -> some SwiftUI.View {
		preferences(destinationStore)
			.transfer(destinationStore)
	}

	func preferences(_ destinationStore: PresentationStoreOf<AccountDetails.Destinations>) -> some SwiftUI.View {
		navigationDestination(
			store: destinationStore,
			state: /AccountDetails.Destinations.State.preferences,
			action: AccountDetails.Destinations.Action.preferences,
			destination: { AccountPreferences.View(store: $0) }
		)
	}

	func transfer(_ destinationStore: PresentationStoreOf<AccountDetails.Destinations>) -> some SwiftUI.View {
		fullScreenCover(
			store: destinationStore,
			state: /AccountDetails.Destinations.State.transfer,
			action: AccountDetails.Destinations.Action.transfer,
			content: { AssetTransfer.SheetView(store: $0) }
		)
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
					initialState: .init(accountWithInfo: .init(account: .previewValue0)),
					reducer: AccountDetails.init
				)
			)
			.navigationBarTitleDisplayMode(.inline)
		}
	}
}
#endif
