import ComposableArchitecture
import SwiftUI
extension AccountDetails.State {
	var viewState: AccountDetails.ViewState {
		.init(
			accountAddress: account.address,
			appearanceID: account.appearanceID,
			displayName: account.displayName.rawValue,
			needToImportMnemonicForThisAccount: importMnemonicPrompt.needed,
			needToBackupMnemonicForThisAccount: exportMnemonicPrompt.needed,
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
		let needToImportMnemonicForThisAccount: Bool
		let needToBackupMnemonicForThisAccount: Bool
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

					Group {
						// Mutally exclusive to prompt user to recover and backup mnemonic.
						if viewStore.needToImportMnemonicForThisAccount {
							importMnemonicPromptView { viewStore.send(.recoverMnemonicsButtonTapped) }
						} else if viewStore.needToBackupMnemonicForThisAccount {
							backupMnemonicPromptView { viewStore.send(.exportMnemonicButtonTapped) }
						}
					}
					.padding(.medium1)

					Button(L10n.Account.transfer, asset: AssetResource.transfer) {
						viewStore.send(.transferButtonTapped)
					}
					.textStyle(.body1Header)
					.foregroundColor(.app.white)
					.padding(.horizontal, .large2)
					.frame(height: .standardButtonHeight)
					.background(.app.whiteTransparent3)
					.cornerRadius(.standardButtonHeight / 2)
					.padding(.bottom, .medium1)

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
			.navigationDestination(
				store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
				state: /AccountDetails.Destinations.State.preferences,
				action: AccountDetails.Destinations.Action.preferences,
				destination: { AccountPreferences.View(store: $0) }
			)
			.fullScreenCover(
				store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
				state: /AccountDetails.Destinations.State.transfer,
				action: AccountDetails.Destinations.Action.transfer,
				content: { AssetTransfer.SheetView(store: $0) }
			)
			.fullScreenCover( /* Full Screen cover to prevent iOS dismiss gestures */
				store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
				state: /AccountDetails.Destinations.State.exportMnemonic,
				action: AccountDetails.Destinations.Action.exportMnemonic,
				content: { childStore in
					NavigationView {
						ImportMnemonic.View(store: childStore)
							.navigationTitle(L10n.ImportMnemonic.navigationTitleBackup)
					}
				}
			)
			.sheet(
				store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
				state: /AccountDetails.Destinations.State.importMnemonics,
				action: AccountDetails.Destinations.Action.importMnemonics,
				content: { ImportMnemonicsFlowCoordinator.View(store: $0) }
			)
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
					initialState: .init(for: .previewValue0),
					reducer: AccountDetails.init
				)
			)
			.navigationBarTitleDisplayMode(.inline)
		}
	}
}
#endif
